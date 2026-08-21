load(
    "//bazel:envoy_build_system.bzl",
    "envoy_cc_extension",
    "envoy_extension_package",
)

licenses(["notice"])  # Apache 2

# LOCAL-ONLY reproducer filter for https://github.com/envoyproxy/envoy/issues/46841 -- do NOT upstream.

envoy_extension_package()

envoy_cc_extension(
    name = "config",
    srcs = ["config.cc"],
    deps = [
        "//envoy/http:filter_interface",
        "//envoy/registry",
        "//envoy/server:filter_config_interface",
        "//source/common/protobuf",
        "//source/extensions/filters/http/common:pass_through_filter_lib",
    ],
)
