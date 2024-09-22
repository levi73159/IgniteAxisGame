pub fn moveToward(point: f32, to: f32, step: f32) f32 {
    return if (point < to)
        @min(point + step, to)
    else if (point > to) 
       @max(point - step, to)
    else 
        to;
}