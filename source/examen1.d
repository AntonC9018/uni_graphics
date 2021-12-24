import arsd.simpledisplay;
import common.util;
import std.stdio;

void main(string[] args)
{
    if (args.length == 1)
    {
        writeln("Call with `program_name 1|2|3");
        return;
    }

    auto window = new SimpleWindow();

	window.eventLoop(1000 / 60, 
	{
		auto painter = window.draw();
        
        switch (args[1])
        {
            case "1": first(window, painter);   break;
            case "2": second(window, painter);  break;
            case "3": third(window, painter);   break;
            default: 
        }
    });
}

void first(SimpleWindow window, ref ScreenPainter painter)
{
    painter.clear();
    painter.outlineColor = Color.black;
    painter.fillColor = Color.black;

    const fdimension = 10;
    const fmin = v2(-5, -3); // x and y
    const fmax = fmin + fdimension;
    const fcenter = (fmin + fmax) / 2;
    
    const wdimensions = v2(window.width, window.height);
    const wcenter = wdimensions / 2;

    {
        const fleft = v2(fmin[0], 0.5 - fmin[0]);
        const fright = v2(fmax[0], 0.5 - fmax[0]);
        const v2[2] fpositions = [ fleft, fright ]; 
        v2[2] wpositions;
        foreach (i, pos; fpositions)
            wpositions[i] = (pos - fcenter) / fdimension * wdimensions * v2(1, -1) + wcenter;
        painter.drawLine(wpositions[0].point, wpositions[1].point);
    }
    {
        const y = (-fcenter.y - 0.5) / fdimension * wdimensions.y * -1 + wcenter.y; // y + 1/2 = 0;
        const int[2] xs = [0, window.width];
        painter.drawLine(Point(xs[0], cast(int) y), Point(xs[1], cast(int) y)); 
    }
}

void second(SimpleWindow window, ref ScreenPainter painter)
{
    painter.clear();

    foreach (int rowIndex; 0..7)
    {
        painter.outlineColor = Color.black;
        foreach (int colIndex; [0, 1, 4, 5])
            painter.drawPixel(Point(colIndex, rowIndex));

        painter.outlineColor = Color.white;
        foreach (int colIndex; [2, 3])
            painter.drawPixel(Point(colIndex, rowIndex));
    }
    {
        int rowIndex = 7;

        painter.outlineColor = Color.black;
        foreach (int colIndex; [1, 2, 3, 4])
            painter.drawPixel(Point(colIndex, rowIndex));
        
        painter.outlineColor = Color.white;
        foreach (int colIndex; [0, 5])
            painter.drawPixel(Point(colIndex, rowIndex));
    }
}

void third(SimpleWindow window, ref ScreenPainter painter)
{
    painter.clear();
    painter.outlineColor = Color.black;
    painter.fillColor = Color.white;

    v2[4][2] rectPoints = [
        [ v2(0, 1), v2(-1, 2), v2(-1, 4), v2(0, 3), ],
        [ v2(1, 0), v2(1, 1),  v2(3, 1),  v2(3, 0), ],
    ];
    
    const fmin = v2(-5, -5);
    const fmax = v2(5, 5);
    const fdimensions = fmax - fmin;
    const wdimenstions = v2(window.width, window.height);
    const screenCenter = wdimenstions / 2;

    foreach (ref p; cast(v2[]) rectPoints[])
        p = p * v2(1, -1) / fdimensions * wdimenstions + screenCenter;

    foreach (v2[4] rect; rectPoints)
    {
        Point[4] verts;
        foreach (i, p; rect)
            verts[i] = p.point;

        painter.drawPolygon(verts[]);
    }

    painter.drawLine(Point(0, window.height / 2), Point(window.width, window.height / 2));
    painter.drawLine(Point(window.width / 2, 0),  Point(window.width / 2, window.height));
}