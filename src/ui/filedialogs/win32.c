/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifdef _WIN32
#define COBJMACROS
#include <windows.h>
#include <shobjidl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>

struct file_list {
    wchar_t** files;
    _int64 len;
};

static HRESULT ShowOpenFileDialog(PCWSTR title, BOOL multiple, const COMDLG_FILTERSPEC* filters, UINT len,
    struct file_list* res);

static HRESULT ShowSaveFileDialog(PCWSTR title, const COMDLG_FILTERSPEC* filters, UINT len, struct file_list* res);

/* MUST be called on a SEPARATE THREAD */
struct file_list win32_open_file(wchar_t *title, bool multiple, wchar_t *ext)
{
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

    COMDLG_FILTERSPEC filters[] = {
        { .pszName = L"Supported Images", .pszSpec = ext },
    };

    struct file_list res = { 0 };

    HRESULT hr = ShowOpenFileDialog(
        title,
        multiple,
        filters,
        ARRAYSIZE(filters),
        &res
    );

    if (!SUCCEEDED(hr))
        res.len = -1;

    CoUninitialize();

    return res;
}

/* MUST be called on a SEPARATE THREAD */
struct file_list win32_save_file(wchar_t *title, wchar_t *ext)
{
    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

    COMDLG_FILTERSPEC filters[] = {
        { .pszName = L"OPNG Models", .pszSpec = ext },
    };

    struct file_list res = { 0 };

    HRESULT hr = ShowSaveFileDialog(
        title,
        filters,
        ARRAYSIZE(filters),
        &res
    );

    if (!SUCCEEDED(hr))
        res.len = -1;

    CoUninitialize();

    return res;
}

static HRESULT ShowOpenFileDialog(PCWSTR title, BOOL multiple, const COMDLG_FILTERSPEC* filters, UINT len,
    struct file_list* res)
{
    if (!res) return E_POINTER;

    IFileOpenDialog *pfd = NULL;
    IShellItemArray *arr = NULL;
    DWORD flags = 0;

    HRESULT hr = CoCreateInstance(&CLSID_FileOpenDialog, NULL, CLSCTX_INPROC_SERVER,
        &IID_IFileOpenDialog, (void**) &pfd);
    if (FAILED(hr)) return hr;

    IFileOpenDialog_SetTitle(pfd, title);
    IFileOpenDialog_SetFileTypes(pfd, len, filters);
    IFileOpenDialog_SetFileTypeIndex(pfd, 1);

    if (SUCCEEDED(IFileOpenDialog_GetOptions(pfd, &flags))) {
        flags |= FOS_FORCEFILESYSTEM;
        if (multiple) flags |= FOS_ALLOWMULTISELECT;
        else flags &= ~FOS_ALLOWMULTISELECT;

        IFileOpenDialog_SetOptions(pfd, flags);
    }

    hr = IFileOpenDialog_Show(pfd, NULL);
    if (FAILED(hr)) goto cleanup;

    hr = IFileOpenDialog_GetResults(pfd, &arr);
    if (FAILED(hr)) goto cleanup;

    DWORD count = 0;
    IShellItemArray_GetCount(arr, &count);
    if (count == 0) goto cleanup;

    wchar_t** pathArray = calloc(count, sizeof(wchar_t*));
    if (!pathArray) {
        hr = E_OUTOFMEMORY;
        goto cleanup;
    }

    for (DWORD i = 0; i < count; i++) {
        IShellItem *pItem = NULL;
        if (SUCCEEDED(IShellItemArray_GetItemAt(arr, i, &pItem))) {
            PWSTR pszFilePath = NULL;
            if (SUCCEEDED(IShellItem_GetDisplayName(pItem, SIGDN_FILESYSPATH, &pszFilePath))) {

                pathArray[i] = _wcsdup(pszFilePath);

                CoTaskMemFree(pszFilePath);
            }
            IShellItem_Release(pItem);
        }
    }

    res->files = pathArray;
    res->len = count;

cleanup:
    if (arr) IShellItemArray_Release(arr);
    if (pfd) IFileOpenDialog_Release(pfd);

    return hr;
}

static HRESULT ShowSaveFileDialog(PCWSTR title, const COMDLG_FILTERSPEC* filters, UINT len, struct file_list* res)
{
    if (!res) return E_POINTER;

    IFileSaveDialog *pfd = NULL;
    IShellItem *item = NULL;
    DWORD flags = 0;

    HRESULT hr = CoCreateInstance(&CLSID_FileSaveDialog, NULL, CLSCTX_INPROC_SERVER,
        &IID_IFileSaveDialog, (void**)&pfd);
    if (FAILED(hr)) return hr;

    IFileSaveDialog_SetTitle(pfd, title);
    IFileSaveDialog_SetFileTypes(pfd, len, filters);
    IFileSaveDialog_SetFileTypeIndex(pfd, 1);

    if (SUCCEEDED(IFileSaveDialog_GetOptions(pfd, &flags))) {
        flags |= FOS_FORCEFILESYSTEM | FOS_FORCESHOWHIDDEN;
        IFileSaveDialog_SetOptions(pfd, flags);
    }

    hr = IFileSaveDialog_Show(pfd, NULL);
    if (FAILED(hr)) goto cleanup;

    hr = IFileSaveDialog_GetResult(pfd, &item);
    if (FAILED(hr)) goto cleanup;

    PWSTR pszFilePath = NULL;
    hr = IShellItem_GetDisplayName(item, SIGDN_FILESYSPATH, &pszFilePath);
    if (SUCCEEDED(hr)) {
        wchar_t** pathArray = calloc(1, sizeof(wchar_t*));
        pathArray[0] = _wcsdup(pszFilePath);
        CoTaskMemFree(pszFilePath);

        res->files = pathArray;
        res->len = 1;
    }

cleanup:
    if (item) IShellItem_Release(item);
    if (pfd) IFileSaveDialog_Release(pfd);

    return hr;
}

#endif