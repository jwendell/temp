#include <string>

#include "envoy/registry/registry.h"
#include "envoy/server/filter_config.h"
#include "extensions/filters/http/jwendell/config.h"
#include "extensions/filters/http/jwendell/decoder.h"

namespace Envoy {
namespace Extensions {
namespace HttpFilters {
namespace JWendell {

Http::FilterFactoryCb SampleDecoderFilterConfig::createFilterFactoryFromProtoTyped(
    const envoy::extensions::filters::http::jwendell::v3::Decoder& proto_config,
    const std::string&, Server::Configuration::FactoryContext&) {

  auto filter = std::make_shared<SampleDecoderFilter>(proto_config);

  return [filter](Http::FilterChainFactoryCallbacks& callbacks) -> void {
    callbacks.addStreamDecoderFilter(filter);
  };
}

REGISTER_FACTORY(SampleDecoderFilterConfig,
                 Server::Configuration::NamedHttpFilterConfigFactory){"envoy.jwendell"};

} // namespace JWendell
} // namespace HttpFilters
} // namespace Extensions
} // namespace Envoy
