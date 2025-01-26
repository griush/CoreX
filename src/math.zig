pub const Vec2 = [2]f32;
pub const Vec3 = [3]f32;
pub const Vec4 = [4]f32;

pub fn scale(vec: anytype, scalar: f32) @TypeOf(vec) {
    if (@TypeOf(vec) != Vec2 and @TypeOf(vec) != Vec3 and @TypeOf(vec) != Vec4) {
        @compileError("math.scale() not implemented for non vec types");
    }

    const T = @TypeOf(vec);
    var v: T = @splat(0.0);
    for (vec, 0..) |c, i| {
        v[i] = c * scalar;
    }
    return v;
}

pub fn magnitude(vec: anytype) f32 {
    if (@TypeOf(vec) != Vec2 and @TypeOf(vec) != Vec3 and @TypeOf(vec) != Vec4) {
        @compileError("math.magnitude() not implemented for non vec types");
    }

    var sum: f32 = 0.0;
    for (vec) |c| {
        sum += c * c;
    }
    return @sqrt(sum);
}

pub fn normalize(vec: anytype) @TypeOf(vec) {
    if (@TypeOf(vec) != Vec2 and @TypeOf(vec) != Vec3 and @TypeOf(vec) != Vec4) {
        @compileError("math.normalize() not implemented for non vec types");
    }

    const m = magnitude(vec);
    const T = @TypeOf(vec);
    var v: T = @splat(0.0);
    for (vec, 0..) |c, i| {
        v[i] = c / m;
    }
    return v;
}
