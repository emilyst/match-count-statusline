# Contributing

This plugin has a limited scope. I do not intend to implement indexing
at this time (meaning, I do not intend to display which of the matches
your cursor is on). Proposals or requests to widen the scope will be
rejected.

Performance improvements, bug fixes, and compatibility improvements are
welcome, provided that the change matches the style of the rest of the
plugin, does not introduce needless complexity, and complies with the
following guidelines for commits and pull requests.


## Commits and Pull Requests

Each commit should contain a single, discrete change which does not
break when applied in isolation. It should be possible to use
`git-bisect(1)` on your commits. Do not use merge commits.

Each commit message should begin with a title of about fifty characters
in length, written in the active tense, imperative mood describing the
change briefly, followed by a blank line, followed by a longer
description of the change hard-wrapped to seventy-two columns or less.
The description should state why the change was necessary.

A pull request may have multiple commits if necessary. Each pull request
should address a single problem. It should describe the problem it
addresses and how it intends to solve it. The commits for that pull
request should solve the problem.
