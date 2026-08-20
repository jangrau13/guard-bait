/** Choosing one coordinator among peers that can all see each other. */
public class Election {
    private final String self;
    private final java.util.Set<String> peers;

    public Election(String self, java.util.Set<String> peers) {
        this.self = self;
        this.peers = peers;
    }

    /** The id of the peer that should coordinate right now. */
    public String coordinator() {
        throw new UnsupportedOperationException("not implemented");
    }

    /** Called when a peer stops answering. */
    public void lost(String peer) {
        throw new UnsupportedOperationException("not implemented");
    }
}
