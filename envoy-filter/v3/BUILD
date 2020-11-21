load(
    "//bazel:envoy_build_system.bzl",
    "envoy_cc_extension",
    "envoy_cc_library",
    "envoy_extension_package",
    "envoy_proto_library",
)

licenses(["notice"])  # Apache 2

envoy_extension_package()

envoy_proto_library(
    name = "decoder",
    srcs = ["decoder.proto"],
)

envoy_cc_library(
    name = "decoder_lib",
    srcs = ["decoder.cc"],
    hdrs = ["decoder.h", "config.h"],
    deps = [
        ":decoder_cc_proto",
        "//source/extensions/filters/http/common:factory_base_lib",
        "//source/extensions/filters/http/common:pass_through_filter_lib",
    ],
)

envoy_cc_extension(
    name = "config",
    srcs = ["config.cc"],
    hdrs = ["config.h"],
    security_posture = "robust_to_untrusted_downstream",
    deps = [
        "//include/envoy/registry",
        "//source/common/http:header_utility_lib",
        "//source/extensions/filters/http/common:factory_base_lib",
        "//source/extensions/filters/http/jwendell:decoder_lib",
        "//include/envoy/server:filter_config_interface",

    ],
)
