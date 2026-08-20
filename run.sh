#!/bin/sh
# What the examiner may run against the submitted election rule.
#
# Election has no main of its own, so every target here is a driver compiled
# beside the candidate's classes. javac writes class files next to the source
# and the checkout is not ours to write into, so everything is assembled in
# /build.
#
# Each peer is given its own Set. Two peers do not share memory, and a rule
# that quietly edits the set it was handed would otherwise reach across the
# split and answer for both halves at once.
set -eu
mkdir -p "${TMPDIR:-/build/tmp}"

W=/build/viva-run

list() {
    printf '%s\t%s\n' elect \
        'Builds one peer holding a live set of four and prints who it elects, then who it elects after each peer it is told has stopped answering. The plain run.'
    printf '%s\t%s\n' agreement \
        'Four peers holding the same live set in sets that hand the ids out in different orders. Fails if they do not all elect the same peer.'
    printf '%s\t%s\n' losses \
        'The same two failures, delivered to peers in different orders. Fails if the answer depends on the order the losses arrived rather than on who is left.'
    printf '%s\t%s\n' partition \
        'Splits the four peers into two halves that cannot see each other and lets each elect. Shows what the candidate believes cannot happen; both outcomes are worth reading.'
}

# The candidate's classes, whatever else they added beside Election.
prepare() {
    rm -rf "$W"
    mkdir -p "$W"
    [ -f /work/Election.java ] || { echo "the submission has no Election.java at its root"; exit 2; }
    cp /work/*.java "$W/"
}

TARGET="${1:-elect}"
if [ "$TARGET" = "--list" ]; then
    list
    exit 0
fi

prepare

case "$TARGET" in
elect)
    CLASS=VivaElect
    cat > "$W/VivaElect.java" <<'SRC'
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/** One peer's view of four, and what it elects as the others stop answering. */
public class VivaElect {
    public static void main(String[] args) {
        List<String> all = List.of("alpha", "bravo", "charlie", "delta");
        Election e = new Election("alpha", new LinkedHashSet<>(all));

        System.out.println("peer alpha, live set " + all);
        String got = e.coordinator();
        System.out.println("  coordinator: " + got);
        boolean ok = got != null && all.contains(got);
        if (!ok) System.out.println("  " + got + " is not one of the peers");

        // The live set as this peer has been told it is, kept here rather than
        // read back out of the Election: what it did with the losses is the
        // thing being looked at.
        Set<String> live = new LinkedHashSet<>(all);
        for (String gone : List.of("delta", "charlie")) {
            live.remove(gone);
            e.lost(gone);
            got = e.coordinator();
            System.out.println("lost " + gone + " -> coordinator: " + got);
            if (got == null || !live.contains(got)) {
                System.out.println("  " + got + " has been reported gone");
                ok = false;
            }
        }
        System.out.println(ok ? "elects a peer it has been given no reason to doubt"
                              : "ELECTS A PEER IT HAS BEEN TOLD IS GONE");
        if (!ok) System.exit(1);
    }
}
SRC
    ;;
agreement)
    CLASS=VivaAgreement
    cat > "$W/VivaAgreement.java" <<'SRC'
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;

/** The same four peers, in sets that hand them out in different orders. */
public class VivaAgreement {
    public static void main(String[] args) {
        List<String> peers = List.of("delta", "alpha", "charlie", "bravo");
        List<String> reversed = new ArrayList<>(peers);
        Collections.reverse(reversed);
        Set<String> descending = new TreeSet<>(Comparator.reverseOrder());
        descending.addAll(peers);

        // Every one of these holds the same four ids and iterates them
        // differently. A rule that keeps the first id it is handed answers a
        // different one to each.
        List<Set<String>> views = new ArrayList<>();
        views.add(new LinkedHashSet<>(peers));
        views.add(new LinkedHashSet<>(reversed));
        views.add(new TreeSet<>(peers));
        views.add(descending);
        views.add(new HashSet<>(peers));

        String first = null;
        boolean agree = true;
        for (int i = 0; i < views.size(); i++) {
            Set<String> view = views.get(i);
            String self = peers.get(i % peers.size());
            String got = new Election(self, view).coordinator();
            System.out.println("peer " + self + " seeing " + view + " elects: " + got);
            if (i == 0) first = got;
            else if (!Objects.equals(first, got)) agree = false;
        }
        System.out.println(agree ? "every peer reached the same answer"
                                 : "PEERS DISAGREE on the same live set");
        if (!agree) System.exit(1);
    }
}
SRC
    ;;
losses)
    CLASS=VivaLosses
    cat > "$W/VivaLosses.java" <<'SRC'
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;

/** The same two failures, reaching different peers in different orders. */
public class VivaLosses {
    public static void main(String[] args) {
        List<String> peers = List.of("alpha", "bravo", "charlie", "delta");
        List<List<String>> orders = List.of(
            List.of("delta", "charlie"),
            List.of("charlie", "delta"));

        // Two ways for these to come apart, and they are different faults: one
        // peer answering itself differently depending on the order, and two
        // peers left with the same live set answering differently at all.
        boolean orderMatters = false;
        boolean peersDisagree = false;
        String across = null;
        boolean haveAcross = false;

        for (String self : List.of("alpha", "bravo")) {
            String mine = null;
            boolean haveMine = false;
            for (List<String> order : orders) {
                Election e = new Election(self, new LinkedHashSet<>(peers));
                for (String gone : order) e.lost(gone);
                String got = e.coordinator();
                System.out.println("peer " + self + ", told " + order + " gone, elects: " + got);
                if (!haveMine) { mine = got; haveMine = true; }
                else if (!Objects.equals(mine, got)) orderMatters = true;
            }
            if (!haveAcross) { across = mine; haveAcross = true; }
            else if (!Objects.equals(across, mine)) peersDisagree = true;
        }

        if (orderMatters) System.out.println("THE ANSWER DEPENDS ON THE ORDER THE LOSSES ARRIVED");
        if (peersDisagree) System.out.println("PEERS LEFT WITH THE SAME LIVE SET DISAGREE");
        if (!orderMatters && !peersDisagree)
            System.out.println("the answer followed from who is left, not from the order they went");
        if (orderMatters || peersDisagree) System.exit(1);
    }
}
SRC
    ;;
partition)
    CLASS=VivaPartition
    cat > "$W/VivaPartition.java" <<'SRC'
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;

/** Two halves of a split network, each with its own view, each electing. */
public class VivaPartition {
    public static void main(String[] args) {
        List<String> all = List.of("alpha", "bravo", "charlie", "delta");

        Election left = new Election("alpha", new LinkedHashSet<>(all));
        left.lost("charlie");
        left.lost("delta");

        Election right = new Election("charlie", new LinkedHashSet<>(all));
        right.lost("alpha");
        right.lost("bravo");

        String a = left.coordinator();
        String b = right.coordinator();
        System.out.println("half {alpha, bravo} elects:   " + a);
        System.out.println("half {charlie, delta} elects: " + b);
        System.out.println(Objects.equals(a, b)
            ? "both halves agree"
            : "SPLIT BRAIN — two coordinators at once, and neither knows");
    }
}
SRC
    ;;
*)
    printf 'no such target: %s\n' "$TARGET" >&2
    list >&2
    exit 2
    ;;
esac

cd "$W"
javac -d . ./*.java 2>&1 || exit 1
java -cp . "$CLASS"
