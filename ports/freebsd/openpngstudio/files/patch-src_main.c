Use absolute path for assets

Index: src/main.c
--- src/main.c.orig	2024-12-07 21:35:44 UTC
+++ src/main.c
@@ -19,7 +19,7 @@
 #include <unistd.h>
 #include <uv.h>
 
-#define PATH_START "../"
+#define PATH_START "%%LOCALBASE%%/share/openpngstudio"
 
 static char image_filter[] = "png;bmp;jpg;jpeg;gif";
 
