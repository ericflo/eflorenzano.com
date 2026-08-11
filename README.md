# eflorenzano.com

The static source for `eflorenzano.com` and its unprivileged nginx image.

Pushes to `master` run `.woodpecker.yaml` on the Epsilon cluster. A successful
validation and image build publishes an immutable internal image; Flux records
its exact digest in Epsilon and rolls it out. Epsilon alone owns Kubernetes
configuration and runtime secrets, so routine releases need only this
repository's commit and push.
