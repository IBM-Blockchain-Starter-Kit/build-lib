# Contributing to Blockchain Starter Kit

These are the guidelines we try to follow while working on the starter kit. We welcome contributions!

## Got a Question or Problem?

We are at an early stage of development however if you have questions about how to use the toolkit please get in touch using our [Gitter room](https://gitter.im/IBM-Blockchain-Starter-Kit/Lobby?utm_source=share-link&utm_medium=link&utm_campaign=share-link).

## Found a Bug?

If you find a bug, you can help us by reporting the [issue](https://github.com/IBM-Blockchain-Starter-Kit/build-lib/issues):

- If there is already an issue open for the problem, any additional information you can provide would be really useful.

- If there is not already an issue open, please create one and include as much detail as possible to help us track down the problem.

Even better, you can submit a Pull Request with a fix!

## Our Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

We use our own forks and [Github Flow](https://guides.github.com/introduction/flow/index.html) to deliver changes to the code:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests.
3. If you've added any new features or made breaking changes, update the documentation.
4. Ensure all the tests pass.
5. Include a descriptive message and the [Developer Certificate of Origin (DCO) sign-off](https://github.com/probot/dco#how-it-works) on all commit messages.
6. Issue a pull request!

## Coding Style

* 2 spaces for indentation rather than tabs.
* Please to try to be consistent with the rest of the code and conform to lint rules where they are provided.

## Git cheatsheet

Configure your identity:

```
git config --global user.name "John Doe"
git config --global user.email johndoe@example.com
```

Clone your forked repository:

```
git clone <forked_repository>
```

Add original repository as the upstream remote:

```
git remote add upstream <original_repository>
```

Make your changes in a new git branch:

```
git fetch upstream master
git checkout -b my-fix-branch upstream/master
```

Add changes for committing:

```
git add .
```

Commit your changes including the DCO sign-off:

```
git commit -s
```

Push your branch to GitHub:

```
git push origin my-fix-branch
```

### Git resources

* [Git Handbook](https://guides.github.com/introduction/git-handbook/)
* [Git Guide](http://rogerdudler.github.io/git-guide/)
* [Git homepage](https://www.git-scm.com)
