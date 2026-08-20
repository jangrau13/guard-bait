#!/bin/sh
# Does the submitted Java build? The answer a patch is admitted on.
#
# Every .java at the root of the checkout, not Election alone: a submission
# that split its rule across classes still has to compile as a whole for
# anything to run against it.
#
# A stub compiled alongside names the constructor and the two methods the
# assignment declares, so a patch that removes or reshapes one of them fails
# here, with the compiler saying so, rather than as a run that never started.
#
# javac writes class files next to the source and the checkout is not ours to
# write into, so the output goes to /build.
set -eu
mkdir -p "${TMPDIR:-/build/tmp}"

W=/build/viva-compile
rm -rf "$W"
mkdir -p "$W"

[ -f /work/Election.java ] || { echo "the submission has no Election.java at its root"; exit 2; }
cp /work/*.java "$W/"

cat > "$W/VivaInterface.java" <<'SRC'
/** Never run: it exists so that the shape the assignment declares is compiled. */
final class VivaInterface {
    static String use() {
        Election e = new Election("alpha", new java.util.HashSet<>(java.util.List.of("alpha")));
        String c = e.coordinator();
        e.lost("alpha");
        return c;
    }
}
SRC

cd "$W"
javac -d . ./*.java 2>&1 || exit 1
echo "the submission builds"
