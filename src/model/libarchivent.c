#ifdef _WIN32
/* couldn't get libarchive to compile for whatever reason */
void archive_write_new() {}
void archive_write_add_filter_zstd() {}
void archive_write_set_format_pax_restricted() {}
void archive_write_open_filename() {}
void archive_write_close() {}
void archive_write_free() {}
void archive_entry_new() {}
void archive_entry_set_pathname() {}
void archive_entry_set_size() {}
void archive_entry_set_filetype() {}
void archive_entry_set_perm() {}
void archive_write_header() {}
void archive_write_data() {}
void archive_entry_free() {}
void archive_read_new() {}
void archive_read_support_filter_zstd() {}
void archive_read_support_format_tar() {}
void archive_read_open_memory() {}
void archive_read_next_header() {}
void archive_read_close() {}
void archive_read_free() {}
void archive_entry_filetype() {}
void archive_entry_pathname() {}
void archive_entry_size() {}
void archive_read_data() {}
void archive_read_data_skip() {}
#endif