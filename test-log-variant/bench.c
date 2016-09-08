// compile with gcc $(pkg-config --cflags --libs glib-2.0) bench.c -o bench

#include <glib.h>
#include <glib/gprintf.h>

#define N_ELEMENTS 10 * 1024 * 1024 // 10 MB of blob
#define N_FIELDS 100                // How many journal binary fields

static GVariant *
create (guchar *values) {
  GVariant *v;
  GVariantBuilder b;
  char field_name[50];

  g_variant_builder_init (&b, G_VARIANT_TYPE ("a{sv}"));
  g_variant_builder_add (&b, "{sv}", "BENCH", g_variant_new_int32 (42));
  g_variant_builder_add (&b, "{sv}", "MESSAGE", g_variant_new_string ("Let's benchmarch!"));

  for (int i = 1; i <= N_FIELDS; i++)
    {
       g_sprintf (field_name, "BINARY_FIELD_%d", i);
       GVariant *y = g_variant_new_fixed_array (G_VARIANT_TYPE_BYTE, values, N_ELEMENTS, sizeof (values[0]));
       g_variant_builder_add (&b, "{sv}", field_name, y);
    }
  
  return g_variant_builder_end (&b);
}

int main(int argc, char **argv) {
  guchar *values = g_new (guchar, N_ELEMENTS);
  for (int i = 0; i < N_ELEMENTS; i++)
    {
      values[i] = g_random_int_range (0, 255);
    }

  GVariant *v = create(values);
  g_log_variant (NULL, G_LOG_LEVEL_MESSAGE, v);

  g_free (values);
  g_variant_unref (v);
  return 0;
}
