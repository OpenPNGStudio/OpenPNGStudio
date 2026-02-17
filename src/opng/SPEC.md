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

*Directory type - type of data stored in the directory: `0 (SQLite), 1 (Images)`<br>
*Directory offset - file cursor position from the start where data is located<br>

`SQLite` header:

| Offset | Size | Description            |
| ------ | ---- | ---------------------- |
| 0x0    | 0x8  | SQLite serialized size |
| 0x8    | 0x8  | Data offset            |

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

> Note: every image is stored using QOI format (for now)