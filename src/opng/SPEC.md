# File Format Specification 0.3
`OPNG` is a custom file format created for `OpenPNGStudio` models, it was made to be simple and fast. The format is inspired by DOOM `WAD`s. This format also includes support for optional compression and encryption.
> Note: Every integer is stored as little endian, every ID is larger than 0

## File Structure

Every `OPNG` file begins with a header:

| Offset | Size | Description                 |
| ------ | ---- | --------------------------- |
| 0x0    | 0x4  | Magic*                      |
| 0x4    | 0x2  | Version*                    |
| 0x6    | 0x1  | Compression method*         |
| 0x7    | 0x1  | Password encryption method* |
| 0x8    | 0x1  | Data encryption method*     |

*Magic - 4 byte ASCII string `OPNG`<br>
*Version - major and minor release of `OpenPNGStudio`, e.g: `0x0003` (0.3)<br>
*Compression  method - compression algorithm used: `0 (None)`,  `1 (LZF)`<br>
*Password encryption method - method used to encrypt password: `0 (None)`, `1 (Argon2id)`<br>
*Data encryption method - method used to encrypt data: `0 (None)`, `1 (ChaCha20_Poly1305)`<br>

If compression is present, every algorithm stores own parameters:
> Coming soon

For encryption to be present, both password and data encryption __must__ be present, or neither. Only data are encrypted, not headers, every algorithm stores own parameters:
> Coming soon

Directory info header:
| Offset | Size | Description       |
| ------ | ---- | ----------------- |
| 0x0    | 0x1  | Directory type*   |
| 0x1    | 0x8  | Directory offset* |
| 0x9    | 0x4  | Entry count       |

*Directory type - type of data stored in the directory: `0 (Configuration)`, `1 (Layer Info)`, `2 (Images)`, `3 (Animations)`<br>
*Directory offset - file cursor position from the start where data is located<br>

`Configuration` header:
| Offset | Size | Description              |
| ------ | ---- | ------------------------ |
| 0x0    | 0x8  | Microphone trigger       |
| 0x8    | 0x4  | Microphone sensitivity   |
| 0xC    | 0x4  | Background color (RGBA)* |

*Background color (RGBA) - Alpha is ignored<br>

`Layer Info` header:
| Offset | Size | Description       |
| ------ | ---- | ----------------- |
| 0x0    | 0x4  | X Position offset |
| 0x4    | 0x4  | Y Position offset |
| 0x8    | 0x4  | Rotation          |
| 0xC    | 0x4  | Timeout           |
| 0x10   | 0x1  | Toggle mode*      |
| 0x11   | 0x8  | Mask*             |
| 0x19   | 0x4  | Image ID          |
| 0x1D   | 0x4  | Animation ID      |

*Toggle mode - when enabled, timeout is ignored<br>
*Mask - bit mask of when layer can be shown<br>

`Images` header:
| Offset | Size | Description       |
| ------ | ---- | ----------------- |
| 0x0    | 0x1  | Image Type*       |
| 0x1    | 0x4  | Image ID          |
| 0x5    | 0x8  | Uncompressed Size |
| 0xD    | 0x8  | Size              |
| 0x15   | 0x8  | Image Offset*     |

*Image Type - type of the image: `0 (Static)`, `1 (Animated e.g. GIF)`<br>
*Image Offset - file cursor position from the start where data is located<br>

> Note: every image is stored using QOI format

`Animations` header:
| Offset | Size | Description          |
| ------ | ---- | -------------------- |
| 0x0    | 0x1  | Animation Type*      |
| 0x1    | 0x4  | Animation ID         |
| 0x5    | 0x1  | Animation Easing*    |
| 0x6    | 0x8  | Animation Mask*      |
| 0xE    | 0x4  | Animation Data Size* |

*Animation Type - type of the animation applied to the layer: `0 (Spinner)`, `1 (Shake)`, `2 (Fade)`<br>
*Animation Easing - ID of easing applied to the animation: [list](https://github.com/OpenPNGStudio/OpenPNGStudio/blob/main/src/c3/animation/easings.c3#L7)<br>
*Animation Mask - bit mask of when animation can be played<br>
*Animation Data Size - size of following data of animation<br>
