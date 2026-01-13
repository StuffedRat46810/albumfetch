# albumfetch

**albumfetch** is a command-line interface (CLI) tool written in [Zig](https://ziglang.org/) that displays random albums in the terminal based on list of albums.

This project is heavily inspired by the Unix program **`fortune`**.

## DISCLAIMER
this tool was only created as an hobby to waste time and procrastinate on my actual projects. there's a big chance things won't work at your machine.

## Features

- **Daily Album**: Get a deterministic album recommendation for the current day. Everyone running the tool with the same database gets the same album on the same day although it is highly encouraged to create and use your own personal custom albums.json file.

- **Random Pick**: Roll the dice and get a completely random album from your collection.
- **Theming**: Customize the output colors to match your terminal rice.

## Installation

### Prerequisites
You need the [Zig compiler](https://ziglang.org/download/) installed (tested on recent stable versions, e.g., 0.12+).

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/StuffedRat46810/albumfetch-zig.git
   cd albumfetch-zig

2. Build the project:
   ```bash
   zig build -Doptimize=ReleaseSafe

3. The executable will be available in zig-out/bin/:
   ```bash
   ./zig-out/bin/albumfetch

### Usage
Run the tool from your terminal:
   ```bash
   # Print daily album
   albumfetch --daily
   # OR
   albumfetch -d

   # Get a completely random album
   albumfetch --random
   # OR
   albumfetch -r

   # View version
   albumfetch -v
   ```
## Example Output:
```text
Album:      Selected Ambient Works 85-92
Artist:     Aphex Twin
Genre:      Ambient Techno
Year:       1992
```

### Configuration
On the first run, albumfetch automatically creates a configuration directory at:
**`~/.config/albumfetch/`**

This directory contains:
   1. *`config.json`*: Your main settings and theme configuration.
   2. *`albums.json`*: The database of albums. (the provided database is     small on purpose to encourage personal json files)

## Theming
You can change the colors of the output by editing **`~/.config/albumfetch/config.json`**. Current supported fields are *`label`*, *`album`*, *`artist`*, *`genre`*, and *`year`*.

Example **`/config.json`**:
```json
{
  "albums": "/home/user/.config/albumfetch/albums.json",
  "theme": {
      "label": "cyan",
      "album": "green",
      "artist": "yellow",
      "genre": "magenta",
      "year": "blue"
  }
}
```
Available colors include: black, red, green, yellow, blue, magenta, cyan, white, and gray.
