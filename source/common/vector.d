module common.vector;

import arsd.simpledisplay;

struct v2
{
	float[2] arrayof;

	float x() const { return arrayof[0]; }
	float y() const { return arrayof[1]; }

	this(float x, float y)
	{
		arrayof[0] = x; 
		arrayof[1] = y;
	}

	Point point() const
	{
		return Point(cast(int) x, cast(int) y);
	}

	v2 opBinary(string op)(const v2 rhs) const
	{
		mixin(`return v2(x`, op, `rhs.x,y`, op, `rhs.y);`);
	}

	v2 opBinary(string op)(const float rhs) const
	{
		mixin(`return v2(x`, op, `rhs,y`, op, `rhs);`);
	}

	ref auto opIndex(size_t index)
	{
		return arrayof[index];
	}
}