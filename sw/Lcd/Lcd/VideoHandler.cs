using System;
using System.Timers;

namespace Lcd
{
    class VideoHandler
    {
        public VideoHandler(Eth ethInst, Monitor monitorInst)
        {
            _enable = false;
            _ethernet = ethInst;
            _frameBuffer = new Framebuffer();
            _acc = new Acc();
            _splashScreen = new SplashScreen(monitorInst);
            _dashScreen = new DashScreen(_acc);
            _updateTimer = new System.Timers.Timer(16.666);
            _updateTimer.Elapsed += TimerElapsed;
            _updateTimer.AutoReset = true;
            _updateTimer.Enabled = true;
        }

        private void TimerElapsed(Object source, ElapsedEventArgs e)
        {
            if (_lock)
            {
                return;
            }
            _lock = true;

            if (!_enable)
            {
                if (_acc.TryOpen())
                {
                    _frameBuffer.SetBgColor(0x0D, Colors.ColorIndex.Blue);
                    _frameBuffer.SetBgColor(0x0E, Colors.ColorIndex.Blue);
                    _enable = true;
                }
                else
                {
                    _splashScreen.Get(_frameBuffer);
                    _frameBuffer.UpdateBuffer(_ethernet);
                    _lock = false;
                    return;
                }
            }

            if (!_dashScreen.Get(_frameBuffer))
            {
                _enable = false;
            }
            else
            {
                _frameBuffer.UpdateBuffer(_ethernet);
            }
            _lock = false;
        }

        private Timer _updateTimer;
        private Framebuffer _frameBuffer;
        private SplashScreen _splashScreen;
        private DashScreen _dashScreen;
        private Eth _ethernet;
        private Acc _acc;
        private bool _enable = false;
        private bool _lock = false;
    }
}
