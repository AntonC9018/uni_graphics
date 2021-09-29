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

	const yearColumnIndex = findColumn("2018");
	assert(yearColumnIndex < dataCsv.header.length);
	const dataIndex = [yearColumnIndex, yearColumnIndex + 1, yearColumnIndex + 2];
	const labelIndex = 0;

	const size_t startIndex = 50;
	const size_t dataCount = 25;
	const size_t endIndex = startIndex + dataCount;

	enum numRows = 3;
	float[][numRows] values;
	float[numRows] sums = 0;
	foreach (rowIndex, ref valuesForRow; values)
	{
		valuesForRow = new float[](dataCount);
		foreach (index, ref value; valuesForRow[])
		{
			auto t = dataCsv.data[dataIndex[rowIndex]][index + startIndex];
			if (t)
			{
				value = dataCsv.data[dataIndex[rowIndex]][index + startIndex].toFloatZero();
				if (value > 0)
				{
					sums[rowIndex] += value;
				}
			}
			else
			{
				value = float.nan;
			}
		}
	}

	window.eventLoop(1000 / 60, 
	{
		auto painter = window.draw();
		const backgroundColor = Color.white;
		painter.clear(backgroundColor);
		painter.fillColor = Color.purple;
		// painter.outlineColor = Color.black;

		// How much space the pie leaves from the screen borders
		enum leeway = 0.1;
		// Up to how much the slices go out
		enum displacement = 0.1;

		Point diagramTopLeftCornerOffset = Point(width / 2, 0);
		int pieSpaceSize = min(width - abs(diagramTopLeftCornerOffset.x), height - abs(diagramTopLeftCornerOffset.y));
		int diameter = cast(int) (pieSpaceSize * (1 - leeway - displacement));
		float displacementFactor = displacement * pieSpaceSize / 2;
		Point diagramCenterPosition = screenCenter + diagramTopLeftCornerOffset / 2;

		auto textMaxWidth = diagramTopLeftCornerOffset.x;
		float textLineHeight = cast(float) height / (values[0].length);

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
		doText(dataCsv.header[labelIndex]);

		// Slide the slices in and out
		static offsetVariation = Animation(0, 1, 0.01);
		offsetVariation.update();

		
		enum size_t colorIndexStart = 55;
		// Change this to get a more spread-out palette.
		size_t colorIndex;
		Color currentColor;

		void resetColor() { colorIndex = colorIndexStart; }
		resetColor();

		void nextColor()
		{
			enum skipAmount = 19;
			
			// The index of hex column in the csv
			enum hexIndex = 2;
			currentColor = Color.fromString(colorsCsv.data[hexIndex][colorIndex]);
			colorIndex = (colorIndex + skipAmount) % colorsCsv.numRows; 
		}

		// Draw labels
		resetColor();
		foreach (index; 0..dataCount)
		{
			nextColor();
			pen.color = currentColor;
			painter.pen = pen;
			const label = dataCsv.data[labelIndex][index + startIndex];
			doText(label);
		}

		// How much of the pie the rows are going to take.
		enum rowSpacePercentage = 0.6;
		// Width of row including gaps
		const spacePerRow = rowSpacePercentage / cast(float) (numRows - 1);
		const diameterShrinkPerRow = -spacePerRow * cast(float) diameter / 2;

		// How much of the rows length the gaps are going to override.
		enum gapSizeOfRemainingSpace = 0.5;
		const gapCircleDiameterDifferenceFromTheCurrentDiameter = gapSizeOfRemainingSpace * diameterShrinkPerRow;


		void doPie(size_t rowIndex, float diameter) 
		{
			const totalAngle = 64 * 360;
			float anglePerUnit = cast(float) totalAngle / sums[rowIndex];
			float currentAngle = totalAngle / 4;
			
			Point diagramUpperLeft = diagramCenterPosition - Point(cast(int) diameter / 2, cast(int) diameter / 2);

			resetColor();
			foreach (index, value; values[rowIndex])
			{
				// I have to skip zero since otherwise it thinks I want to draw whole circles.
				if (isNaN(value) || value <= 0)
					continue;
					
				nextColor();
				painter.fillColor = currentColor;

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
					cast(int) diameter, cast(int) diameter, cast(int) currentAngle, cast(int) finishAngle);
				currentAngle = finishAngle;
			}
			
			// Draw a pie diagram vs cover the center of it to get just the outer lines.
			// I think there is no way to apply a mask, so I'm doing that instead.
			enum coverPie = true;
			if (coverPie)
			{
				// Does not need to be normalized, because the variation 
				// actually shows the x displacement / diameter growth.
				const toLeftUpDirection = v2(-1, -1);
				// This accounts for the animation.
				const displacementProjectedLength = displacementFactor * offsetVariation;
				const displacementVector = toLeftUpDirection * displacementProjectedLength;
				// Next account for the actual top left corner.
				// We need to rescale the initial top left corner relative to the center by the constant.
				const coveringCircleDiameter = gapCircleDiameterDifferenceFromTheCurrentDiameter + diameter;
				const actualTopLeftCornerPosition = diagramCenterPosition - 
					Point(cast(int) coveringCircleDiameter / 2, cast(int) coveringCircleDiameter / 2);
				// And this diameter is affected by the animation.
				const coveringCircleAnimatedDiameter = coveringCircleDiameter + displacementProjectedLength * 2;

				painter.fillColor = backgroundColor;
				pen.color = Color.transparent;
				painter.pen = pen;
				painter.drawCircle(actualTopLeftCornerPosition + displacementVector.point, cast(int) coveringCircleAnimatedDiameter);
			}
		}

		float currentDiameter = diameter;
		foreach (i; 0..3)
		{
			doPie(i, currentDiameter);
			currentDiameter += diameterShrinkPerRow;
		}

	});
}