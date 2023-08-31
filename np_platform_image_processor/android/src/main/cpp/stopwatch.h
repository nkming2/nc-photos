#pragma once

#include <chrono>

/**
 * High precision time measurement. Suitable to benchmark codes
 */
class Stopwatch {
public:
  /**
   * Constructor. The instance will by default be started so calling
   * start() right after the constructor is unnecessary
   */
  Stopwatch();

  void start() {
    stop();
    resetClock();
    resume();
  }

  /**
   * Stop the stopwatch. All calls to getters will return the same value
   * until starting again
   */
  void stop() { pause(); }

  /**
   * Resume a previously paused stopwatch
   */
  void resume();

  /**
   * Pause the stopwatch. Will continue counting on resume()
   */
  void pause();

  template <typename T> typename T::rep get() const {
    return std::chrono::duration_cast<T>(getTime()).count();
  }

  /**
   * Return the current measurement, in ns
   *
   * @return
   * @see get()
   */
  int64_t getNs(void) const { return get<std::chrono::nanoseconds>(); }

  /**
   * Return the current measurement, in ms
   *
   * @return
   */
  int64_t getMs() const { return get<std::chrono::milliseconds>(); }

  std::chrono::steady_clock::duration getTime() const;
  void setOffset(std::chrono::steady_clock::duration a_d) { offset_ = a_d; }
  std::chrono::steady_clock::duration getOffset() { return offset_; }
  std::chrono::steady_clock::duration getTimeElapsed() { return time_elapsed_; }
  void resetClock();

private:
  bool is_start_;
  std::chrono::time_point<std::chrono::steady_clock> beg_;
  std::chrono::steady_clock::duration time_elapsed_;
  std::chrono::steady_clock::duration offset_;
};
