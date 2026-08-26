import java.util.Set;
import java.util.HashSet;

public class Election {
    private final String self;
    private final Set<String> alive;

    public Election(String self, Set<String> peers) {
        this.self = self;
        this.alive = new HashSet<>(peers);
        this.alive.add(self);
    }

    // Whoever is alphabetically first among the peers still answering.
    public String coordinator() {
        String best = null;
        for (String p : alive) {
            if (best == null || p.compareTo(best) < 0) best = p;
        }
        return best;
    }

    public void lost(String peer) {
        alive.remove(peer);
    }
}
