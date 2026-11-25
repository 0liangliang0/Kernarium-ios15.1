// SPDX-License-Identifier: GPL-2.0-or-later
#include "jit_memory_preparation.hpp"

#include "cpu/jit_memory/executable_memory.hpp"

#include <limits>

namespace uml::cpu::arm64 {

std::size_t jit_memory_region_bytes(std::size_t total_bytes,
	unsigned executors, std::size_t per_executor_bytes) noexcept
{
	const auto geometry = derive_jit_cache_geometry(
		total_bytes, executors, per_executor_bytes);
	if (!geometry.valid())
		return 0;
	const auto each = geometry.executable_bytes();
	if (each > std::numeric_limits<std::size_t>::max() / executors)
		return 0;
	return each * executors;
}

JitMemoryStatus prepare_jit_memory(std::size_t total_bytes,
	unsigned executors, std::size_t per_executor_bytes) noexcept
{
	/* Without the debugger route the process maps its own executable memory,
	 * as macOS does and as an iOS device does once its signature carries
	 * dynamic-codesigning (which TrollStore applies from the IPA). Nothing has
	 * to be prepared then, but the cache budget is still published, since the
	 * arena sizes itself from it and a boot that asks for the JIT reads it
	 * back; a process whose mapping fails (a plain sideload) keeps the no-JIT
	 * answer. */
	if (!jit_memory::debugger_route()) {
		if (!jit_memory::available())
			return JitMemoryStatus::unsupported;
		if (!jit_cache_budget_publishable(
				total_bytes, executors, per_executor_bytes))
			return JitMemoryStatus::other_settings;
		return set_jit_cache_budget(
			       total_bytes, executors, per_executor_bytes) ?
			JitMemoryStatus::ready : JitMemoryStatus::other_settings;
	}
	const auto bytes = jit_memory_region_bytes(
		total_bytes, executors, per_executor_bytes);
	if (bytes == 0)
		return JitMemoryStatus::failed;
	/* A budget other than the one an earlier JIT run published cannot be set
	 * again, whatever the region holds. */
	if (!jit_cache_budget_publishable(
			total_bytes, executors, per_executor_bytes))
		return JitMemoryStatus::other_settings;
	switch (jit_memory::prepare_debugger_region(bytes)) {
	case jit_memory::RegionStatus::ready:
		return set_jit_cache_budget(
			       total_bytes, executors, per_executor_bytes) ?
			JitMemoryStatus::ready : JitMemoryStatus::other_settings;
	case jit_memory::RegionStatus::unsupported:
		return JitMemoryStatus::unsupported;
	case jit_memory::RegionStatus::no_debugger:
		return JitMemoryStatus::no_debugger;
	case jit_memory::RegionStatus::failed:
	case jit_memory::RegionStatus::smaller:
		return JitMemoryStatus::failed;
	}
	return JitMemoryStatus::failed;
}

bool jit_debugger_attached() noexcept
{
	return jit_memory::debugger_attached();
}

void release_jit_debugger() noexcept
{
	jit_memory::release_debugger();
}

std::size_t prepared_jit_region_bytes() noexcept
{
	return jit_memory::prepared_region_bytes();
}

} // namespace uml::cpu::arm64
