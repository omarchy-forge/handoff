# Release process

Handoff releases are source releases from reviewed commits. Preparing a
candidate does not authorize a tag, GitHub release, visibility change,
marketplace submission, installation, announcement, or website deployment.

## Candidate checklist

1. Confirm the repository is private unless a separate visibility review has
   been approved.
2. Confirm `manifest.json`, `CHANGELOG.md`, and the draft release notes name the
   same semantic version.
3. Review every process invocation and the data migration/first-run path.
4. Run `./scripts/release-check <version>`.
5. Confirm private CI passes at the exact candidate commit.
6. Repeat isolated Quickshell tests after QML or persistence changes.
7. Repeat the backup/install/visual/remove/restore live procedure after changes
   to runtime behavior, installation, or shell integration.
8. Review the diff from the latest released tag. For the first release, review
   the complete repository.
9. Replace `Unreleased` in the changelog heading with the release date only in
   the final approved release commit.

## Publication gate

With explicit approval for the exact version and commit:

1. Create an annotated `v<version>` tag at the reviewed commit.
2. Push only that tag.
3. Create a GitHub release using the reviewed release-notes file.
4. Verify the release points to the expected commit and contains source
   archives only.

Do not create moving tags such as `latest`. Do not publish binaries, packages,
or marketplace entries as part of this source-release procedure.

## After publication

Verify installation from the exact reviewed Git URL/tag in a controlled test,
then remove it and restore local configuration. Record the release in project
memory and open a new `Unreleased` changelog section for subsequent work.
