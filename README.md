![a](https://dl.dropboxusercontent.com/u/4221594/github/darren_200.png) ![b](https://dl.dropboxusercontent.com/u/4221594/github/norma_200.png) ![c](https://dl.dropboxusercontent.com/u/4221594/github/koji_200.png)

identikon
=========

A small collection of Racket scripts for generating identicons. This is very much alpha and will be changing a lot as I learn more about Racket. Identicons can be saved as PNG or SVG.

## CLI interface

```shell

-s  (multi) Size (all identikons are currently squares)
-n  String to convert to identicon (will expand this to take files)
-r  (optional) Ruleset to use
-t  (optional) Filetype to save as: "png" or "svg"; defaults to png

$ racket main.rkt -s 300 -n "FooBarBaz"

$ racket main.rkt -s 300 -n "FooBarBaz" -r "squares.rkt"

$ racket main.rkt -s 300 -n "FooBarBaz" -r "squares.rkt" -t "svg"

$ racket main.rkt -s 300 -s 200 -s 100 -n "FooBarBaz" -r "stars.rkt" -t "svg"
```

## Built-in rule sets

Each identicon has a rules file (ex: `default.rkt`) which is responsible for taking the input data and generating an image as it sees fit. There are a few existing rule sets to play with.

#### default.rkt

![d](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_default.png)

#### circles.rkt

![c](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_circles.png)

#### squares.rkt

![s](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_squares.png)

#### angles.rkt

![a](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_angles.png)

#### angles2.rkt

![a](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_angles2.png)

#### nineblock.rkt

![n](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_nineblock.png)

#### stars.rkt

![s](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_stars.png)

#### rings.rkt

![r](https://dl.dropboxusercontent.com/u/4221594/github/norma_300_rings.png)
