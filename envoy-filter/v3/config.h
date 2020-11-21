#pragma once

#include <string>
#include "source/extensions/filters/http/jwendell/decoder.pb.h"
#include "source/extensions/filters/http/jwendell/decoder.pb.validate.h"
#include "extensions/filters/http/common/factory_base.h"

namespace Envoy {
namespace Extensions {
namespace HttpFilters {
namespace JWendell {

class SampleDecoderFilterConfig
    : public Common::FactoryBase<envoy::extensions::filters::http::jwendell::v3::Decoder> {
public:
  SampleDecoderFilterConfig() : FactoryBase("envoy.filters.http.jwendell") {}

private:
  Http::FilterFactoryCb createFilterFactoryFromProtoTyped(
      const envoy::extensions::filters::http::jwendell::v3::Decoder& proto_config,
      const std::string& stats_prefix, Server::Configuration::FactoryContext& context) override;
};


} // namespace JWendell
} // namespace HttpFilters
} // namespace Extensions
} // namespace Envoy
