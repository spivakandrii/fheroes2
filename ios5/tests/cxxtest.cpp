// Smoke test for the static libc++ on iOS 5: exceptions, filesystem, threads, chrono.
#include <chrono>
#include <cstdio>
#include <filesystem>
#include <map>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <thread>

int main()
{
    try {
        throw std::runtime_error( "exception ok" );
    }
    catch ( const std::exception & e ) {
        std::printf( "%s\n", e.what() );
    }

    std::error_code ec;
    for ( const auto & entry : std::filesystem::directory_iterator( "/var/mobile", ec ) ) {
        std::printf( "fs: %s\n", entry.path().filename().c_str() );
    }

    int value = 0;
    std::thread t( [&value]() { value = 42; } );
    t.join();
    std::printf( "thread: %d\n", value );

    const auto start = std::chrono::steady_clock::now();
    std::this_thread::sleep_for( std::chrono::milliseconds( 50 ) );
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>( std::chrono::steady_clock::now() - start ).count();
    std::printf( "chrono: %lld ms\n", static_cast<long long>( ms ) );

    std::optional<std::string> opt = "optional ok";
    std::printf( "%s\n", opt->c_str() );
    return 0;
}
