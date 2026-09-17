# Hybrid release flow

Local Mac builds the DMG/zip; CI only creates the GitHub Release with generated notes when a version tag is pushed. No notarize and no CI binary build.

1. **Build the DMG (and/or zip) locally** on the Mac mini.
2. **Tag and push** a version tag (`v*`), e.g. `git tag v0.1.2 && git push origin v0.1.2`.
3. **CI creates the release** (`.github/workflows/release-on-tag.yml`) with generated notes — no binaries.
4. **Attach the asset(s)** with `Scripts/attach-release-asset.sh`:

   ```bash
   Scripts/attach-release-asset.sh v0.1.2 ./path/to/Lumiere-0.1.2.dmg
   # or multiple:
   Scripts/attach-release-asset.sh v0.1.2 ./path/to/Lumiere-0.1.2.dmg ./path/to/Lumiere-0.1.2.zip
   ```

Existing Latest release is **v0.1.1**. This automation does not republish or replace it; a new `v*` tag is required for a new release.
