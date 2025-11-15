# File Format Specification 0.3
`OPNG` is a custom file format created for `OpenPNGStudio` models, it was made to be simple and fast. The format is inspired by DOOM `WAD`s. This format also includes support for optional compression and encryption.
> Note: Every integer is stored as little endian

## File Structure

Every `OPNG` file begins with a header:

| Offset | Size | Description                 |
| ------ | ---- | --------------------------- |
| 0x0    | 0x4  | Magic*                      |
| 0x4    | 0x2  | Version*                    |
| 0x6    | 0x4  | Number of directories       |
| 0xA    | 0x1  | Compression  method*        |
| 0xB    | 0x1  | Password encryption method* |
| 0xC		 | 0x1  | Data encryption method*     |

*Magic - 4 byte ASCII string `OPNG`
*Version - major and minor release of `OpenPNGStudio`, e.g: `0x0003` (0.3)
*Compression  method - compression algorithm used: `0 (None)`,  `1 (LZF)`
*Password encryption method - method used to encrypt password: `0 (None)`, `1 (Argon2id)`
*Data encryption method - method used to encrypt data: `0 (None)`, `1 (ChaCha20_Poly1305)`

If compression is present, every algorithm stores own parameters:
> Coming soon

For encryption to be present, both password and data encryption __must__ be present, or neither. Only data are encrypted, not headers, every algorithm stores own parameters:
> Coming soon

Directory info header:
| Offset | Size | Description       |
| ------ | ---- | ----------------- |
| 0x0    | 0x1  | Directory type*   |
| 0x1    | 0x8  | Directory offset* |
| 0x9    | 0x5  | Entry count       |

*Directory type - type of data stored in the directory: `0 (Configuration)`, `1 (Layer Info)`, `2 (Images)`, `3 (Animations)`
*Directory offset - file cursor position from the start where data is located

`Configuration` header:
| Offset | Size | Description              |
| ------ | ---- | ------------------------ |
| 0x0    | 0x8  | Microphone trigger       |
| 0x8    | 0x4  | Microphone sensitivity   |
| 0xC    | 0x4  | Background color (RGBA)* |

*Background color (RGBA) - Alpha is ignored

`Layer Info` header:
| Offset | Size | Description       |
| ------ | ---- | ----------------- |
| 0x0    | 0x4  | X Position offset |
| 0x4    | 0x4  | Y Position offset |
| 0x8    | 0x4  | Timeout           |
| 0xC    | 0x1  | Toggle mode*      |
| 0xD    | 0x4  | Mask*             |
| 0x11   | 0x4  | Image ID          |

*Toggle mode - when enabled, timeout is ignored
*Mask - bit mask of when layer can be shown

`Images` header:
| Offset | Size | Description       |
| ------ | ---- | ----------------- |
| 0x0    | 0x1  | Image Type*       |
| 0x1    | 0x4  | Image ID          |
| 0x0    | 0x8  | Uncompressed Size |
| 0x0    | 0x8  | Unencrypted Size  |
| 0x0    | 0x8  | Size              |
| 0x0    | 0x8  | Image Offset*     |

*Image Type - type of the image: `0 (Static)`, `1 (Animated e.g. GIF)`
*Image Offset - file cursor position from the start where data is located

`Animations` header:
| Offset | Size | Description          |
| ------ | ---- | -------------------- |
| 0x0    | 0x1  | Animation Type*      |
| 0x0    | 0x1  | Animation Easing*    |
| 0x0    | 0x4  | Animation Mask*      |
| 0x0    | 0x4  | Animation Data Size* |

*Animation Type - type of the animation applied to the layer: `0 (None)`, `1 (Spinner)`, `2 (Shake)`, `3 (Fade)`
*Animation Easing - ID of easing applied to the animation: `0 (None)`, [list](https://github.com/OpenPNGStudio/OpenPNGStudio/blob/main/src/c3/animation/easings.c3#L7)
*Animation Mask - bit mask of when animation can be played
*Animation Data Size - size of following data of animation
