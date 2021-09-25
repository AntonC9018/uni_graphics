import arsd.simpledisplay;

import std.range;
import std.algorithm;

import std.math;

import common.util;
import common.csv;

void main(string[] args)
{
	auto window = new SimpleWindow();
	int width() { return window.width; }
	int height() { return window.height; }
	v2 dimensions() { return v2(width, height); }
	Point screenCenter() { return Point(width / 2, height / 2); }

	// https://api.worldbank.org/v2/en/indicator/NY.GDP.PCAP.CD?downloadformat=csv
	auto dataCsv = loadCsv("income.csv");
	// https://github.com/codebrainz/color-names/blob/bba15da1f54d08ecd28614f9d4a98c0bbb74054e/output/colors.csv
	auto colorsCsv = loadCsv("colors.csv");

	size_t findColumn(string name)
	{
		return dataCsv.header.countUntil!(col => col == name);
	}

	const yearColumnIndex = findColumn("2020");
	assert(yearColumnIndex < dataCsv.header.length);
	const dataIndex = yearColumnIndex;
	const labelIndex = 0;

	const size_t startIndex = 50;
	const size_t dataCount = 25;
	const size_t endIndex = startIndex + dataCount;

	float[] values = new float[](dataCount);
	float sum = 0;
	size_t positiveCount = 0;

	foreach (index, ref value; values[])
	{
		auto t = dataCsv.data[dataIndex][index + startIndex];
		if (t)
		{
			value = dataCsv.data[dataIndex][index + startIndex].toFloatZero();
			if (value > 0)
			{
				sum += value;
				positiveCount += 1;
			}
		}
		else
		{
			value = float.nan;
		}
	}

	window.eventLoop(1000 / 60, {
		auto painter = window.draw();
		const backgroundColor = Color.white;
		painter.clear(backgroundColor);
		painter.fillColor = Color.purple;
		// painter.outlineColor = Color.black;

		// How much space the pie leaves from the screen borders
		enum leeway = 0.1;
		// Up to how much the slices go out
		enum displacement = 0.1;

		Point diagramOffset = Point(width / 2, 0);
		int pieSpaceSize = min(width - abs(diagramOffset.x), height - abs(diagramOffset.y));
		int diameter = cast(int) (pieSpaceSize * (1 - leeway - displacement));
		float displacementFactor = displacement * pieSpaceSize / 2;
		Point diagramCenterPosition = screenCenter + diagramOffset / 2;
		Point diagramUpperLeft = diagramCenterPosition - Point(diameter / 2, diameter / 2);

		enum size_t colorIndexStart = 55;
		// Change this to get a more spread-out palette.
		enum skipAmount = 19;
		size_t colorIndex = colorIndexStart;

		auto textMaxWidth = diagramOffset.x;
		float textLineHeight = cast(float) height / (positiveCount + 1);

		Pen pen;
		pen.color = Color.black;
		pen.width = 1;
		painter.pen = pen;

		v2 textCurrentPosition = v2(0, 0);
		v2 textCurrentBottomRightPosition = textCurrentPosition + v2(textMaxWidth, textLineHeight);
		static OperatingSystemFont font = null;
		// 0.8 is an ok heuristic I think.
		if (!font || font.height != cast(int) (textLineHeight * 0.8))
			font = new OperatingSystemFont("Arial", cast(int) (textLineHeight * 0.8));
		painter.setFont(font);

		void doText(string text)
		{
			painter.drawText(textCurrentPosition.point, text, 
				textCurrentBottomRightPosition.point, TextAlignment.Left|TextAlignment.VerticalTop);
			// We assume we draw the text one line at a time.
			textCurrentPosition.y += textLineHeight;
			textCurrentBottomRightPosition.y += textLineHeight;
		}
		doText(dataCsv.header[labelIndex] ~ ": " ~ dataCsv.header[dataIndex]);

		const totalAngle = 64 * 360;
		float anglePerUnit = cast(float) totalAngle / sum;
		float currentAngle = 0;
		// Slide the slices in and out
		static offsetVariation = Animation(0, 1, 0.01);
		offsetVariation.update();

		foreach (index, value; values[])
		{
			// I have to skip zero since otherwise it thinks I want to draw whole circles.
			if (isNaN(value) || value <= 0)
				continue;
				
			// The index of hex column in the csv
			enum hexIndex = 2;
			auto fillColor = Color.fromString(colorsCsv.data[hexIndex][colorIndex]);
			painter.fillColor = fillColor;
			colorIndex = (colorIndex + skipAmount) % colorsCsv.numRows; 

			const angle = anglePerUnit * value;
			const finishAngle = currentAngle + angle;
			const avgAngle = currentAngle + angle / 2;

			// Displace the pie slice off the center
			float radians(T)(T t) { return cast(float) t / 64 / 180 * PI; }
			const normal = v2(cos(radians(avgAngle)), -sin(radians(avgAngle)));
			const displacementVector = normal * displacementFactor * offsetVariation;

			pen.color = Color.transparent;
			painter.pen = pen;
			painter.drawArc(diagramUpperLeft + displacementVector.point, 
				diameter, diameter, cast(int) currentAngle, cast(int) finishAngle);
			currentAngle = finishAngle;
			
			pen.color = fillColor;
			painter.pen = pen;
			const label = dataCsv.data[labelIndex][index + startIndex];
			const valueText = dataCsv.data[dataIndex][index + startIndex];
			doText(label ~ ": " ~ valueText);
		}

		// Draw a pie diagram vs cover the center of it to get just the outer lines.
		// I think there is no way to apply a mask, so I'm doing that instead.
		enum coverPie = true;
		if (coverPie)
		{
			enum howMuchOfThePieToCover = 0.8f;
			// Does not need to be normalized, because the variation 
			// actually shows the x displacement / diameter growth.
			const toLeftUpDirection = v2(-1, -1);
			// This accounts for the animation.
			const displacementProjectedLength = displacementFactor * offsetVariation;
			const displacementVector = toLeftUpDirection * displacementProjectedLength;
			// Next account for the actual top left corner.
			// We need to rescale the initial top left corner by the constant.
			const coveringCircleDiameter = cast(float) diameter * howMuchOfThePieToCover;
			const actualTopLeftCornerPosition = diagramCenterPosition - 
				Point(cast(int) coveringCircleDiameter / 2, cast(int) coveringCircleDiameter / 2);
			// And this diameter is affected by the animation.
			const coveringCircleAnimatedDiameter = coveringCircleDiameter + displacementProjectedLength * 2;

			painter.fillColor = backgroundColor;
			pen.color = Color.transparent;
			painter.pen = pen;
			painter.drawCircle(actualTopLeftCornerPosition + displacementVector.point, cast(int) coveringCircleAnimatedDiameter);
		}
	});
}