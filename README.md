# eflorenzano.com

The static source for `eflorenzano.com` and its unprivileged nginx image.

A push to `master` runs `.woodpecker.yaml` on the Epsilon cluster. Other
branches and pull requests are tested locally and do not execute inside the
production cluster. A successful validation and image build publishes an
immutable internal image; Flux records its exact digest in Epsilon and rolls
it out. Epsilon alone owns Kubernetes configuration and runtime secrets, so a
routine release needs only this repository's commit and push.
