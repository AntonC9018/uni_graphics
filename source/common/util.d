module common.util;

import arsd.simpledisplay;

struct v2
{
	float[2] arrayof;

	ref auto inout x() { return arrayof[0]; }
	ref auto inout y() { return arrayof[1]; }

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


struct Animation
{
	float value;
	float _change;
	float _start;
	float _end;

	alias value this;

	this(float start, float end, float change)
	{
		value = start;
		_change = change;
		_start = start;
		_end = end;
	}

	void update()
	{
		if (value < _start || value > _end)
			_change = -_change;
		value += _change;
	}
}