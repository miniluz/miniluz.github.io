# Justfile for synth-engine table generation
# Usage: just <recipe>

# Default recipe - show available commands
default:
    @just --list

watch:
    @echo "Compiling and watching for changes..."
    @hugo server

build:
    @echo "Compiling and watching for changes..."
    @hugo

format:
    @echo "Formatting"
    @find . -name '*.md' | xargs prettier --write

spell-check:
    @echo "Checking for spelling errors"
    @find . -name '*.md' | xargs cspell

spell-watch:
    @echo "Watching for spelling errors"
    @find . -name '*.md' | entr -c just spell-check

spell-add-unknown:
    @echo "Adding unknown words to dictionary"
    @echo "# Unknown words" >> project-words.txt
    @find . -name '*.md' | xargs cspell --words-only --unique | sort --ignore-case >> project-words.txt

compile:
    @echo "Compiling"
    @typst compile main.typ
