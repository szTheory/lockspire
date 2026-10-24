# Historical upgrade fixture

`v1_45_forward_router.ex.eex` is the exact router template from the annotated
`v1.45` tag object `0f45d0c603c31d814cd9003848f6af508bb4e72c`, peeled to source
commit `69c05922b880d1ee6e257e5a78f06a4e5755efcc` (package version `1.6.1`).
The unrendered template SHA-256 is
`7b1b73ec53d27641166306bce963fcb9e2d7d73ab2059598b9829b92971221c1`.

Tests render this template with the same managed ownership header used by that
source revision, then calculate the manifest checksum from the installed bytes.
This pins the actual historical forward-only helper as authority evidence; the
filename and release label alone never authorize an update.
