# esphome-clang-tidy

Runs ESPHome's `script/clang-tidy` in a Linux container, set up the way the clang-tidy jobs in
ESPHome's `.github/workflows/ci.yml` are: Python 3.12, with the checkout's own
`requirements.txt`, `requirements_dev.txt` and `requirements_test.txt` installed. That includes
the `clang-tidy` version pinned in `requirements_dev.txt`.

Running clang-tidy directly on macOS also checks against the host's own headers, which adds
errors that CI never sees. The old `esphome/esphome-lint` image is no longer built.

## Use

Put `esphome-clang-tidy` on your `PATH` (a symlink is fine), then run it from anywhere inside an
ESPHome checkout or worktree, with the same arguments as `script/clang-tidy`:

```sh
esphome-clang-tidy --all-headers -e esp8266-arduino-tidy esphome/components/lvgl/color_picker.h
esphome-clang-tidy --all-headers --changed -e esp32-arduino-tidy --grep USE_ARDUINO
```

- `--rebuild` builds the image again.
- `--shell` opens a shell in the container instead.
- The container runs as `linux/amd64`, as CI does, even on Apple silicon, where it is emulated
  and slower. clang-tidy checks against the machine it runs on, and the ESP8266 and ESP32
  framework headers use x86 register names in inline assembly, so on ARM they fail with
  `invalid output constraint '=a' in asm`. Set `ESPHOME_TIDY_PLATFORM` to use another platform.

## How it works

- The image is tagged with a hash of the `Dockerfile` and the three requirement files, and is
  built again only when one of them changes.
- The checkout is mounted at the same path it has on the host. For a worktree, the main
  checkout's `.git` folder is mounted as well, since the worktree's `.git` only points to it.
- Toolchains, frameworks and libraries are kept in an `esphome-clang-tidy-home-*` volume, so they
  are downloaded once. The first run for each ESPHome target is slow.
- Each checkout gets its own `.temp` and `.pio` volumes, laid over the folders of the same names,
  so the container and the host never share build data.

To remove everything it has stored:

```sh
docker volume ls -q --filter name=esphome-clang-tidy | xargs docker volume rm
docker image ls -q esphome-clang-tidy | xargs docker image rm
```
