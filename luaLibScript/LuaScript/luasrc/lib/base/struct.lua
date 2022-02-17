OCExtension:defineStruct({
	name = "UIEdgeInsets";
	types = "FFFF";
	keys = {"top", "left", "bottom", "right"}
})

OCExtension:defineStruct({
    name = "CGVector",
    types = "FF",
    keys = { "dx", "dy"}
});

OCExtension:defineStruct({
	name = "UIOffset",
	types = "FF",
	keys = {"horizontal", "vertical"}
})

OCExtension:defineStruct({
    name = "CGSize",
    types = "FF",
    keys = { "width", "height"}
});

OCExtension:defineStruct({
    name = "CGPoint",
    types = "FF",
    keys = { "x", "y"}
});

OCExtension:defineStruct({
    name = "CGRect",
    types = "{CGPoint}{CGSize}",
    keys = { "origin", "size"}
});

OCExtension:defineStruct({
    name = "CGAffineTransform",
    types = "FFFFFF",
    keys = { "a", "b", "c", "d", "tx", "ty"}
});


