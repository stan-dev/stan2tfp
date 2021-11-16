# A Stan-to-TensorFlow Probability Compiler, stan2tfp

[![Build Status](https://jenkins.mc-stan.org/buildStatus/icon?job=stan2tfp%2Fmaster&style=flat-square)](https://jenkins.mc-stan.org/job/stan2tfp/job/master/)


This repo houses the experimental/WIP Stan-to-Tensorflow Probability transpiler.
It uses the frontend and middle-end capabilties of
[stanc3](https://github.com/stan-dev/stanc3) by vendoring that repo as a git
submodule.

This project was originally contained in the same repository as stanc3, but was
moved out following the 2.28.1 release of stanc3 (see [this forum
discussion](https://discourse.mc-stan.org/t/moving-stan2tfp-out-of-stanc3s-repo/24902/)).
This allows development of this package to lag behind the cutting edge without
slowing development of the core C++ backend for Stan.

A Python [wrapper package](https://github.com/adamhaber/stan2tfp) is available
on [PyPi](https://pypi.org/project/stan2tfp/).

The structure of this repository also serves as a template for how further
extensions to the stanc3 compiler can proceed. The stanc3 repository
[exposes](https://mc-stan.org/stanc3/stanc/#modules) packages `stanc.frontend`,
`stanc.middle`, `stanc.common`, and `stanc.analysis` which can be used to build
a new backend and new executable. If a backend reaches a good level of parity
with the C++ backend, it can be considered for formal support within stanc3.

### Notice
This backend currently lacks support for many major features of the Stan
language. If the goal is simply to use Stan from within a Python environment,
[PyStan](https://pystan.readthedocs.io/) and
[CmdStanPy](https://cmdstanpy.readthedocs.io/) both provide Python wrappings to
the C++ backend for Stan.
