#!/bin/bash
# Install Google Test for unit testing

echo "Installing Google Test..."

# Check if already installed
if [ -f "/usr/lib/libgtest.a" ] || [ -f "/usr/local/lib/libgtest.a" ]; then
    echo "Google Test already installed"
    exit 0
fi

# Install development package
sudo apt-get update
sudo apt-get install -y libgtest-dev cmake

# Build and install Google Test
cd /usr/src/gtest
sudo cmake .
sudo make
sudo cp lib/*.a /usr/lib/ 2>/dev/null || sudo cp *.a /usr/lib/

echo "Google Test installation complete!"
echo ""
echo "To build tests, run:"
echo "  cd build"
echo "  mkdir Desktop_Tests"
echo "  cd Desktop_Tests"
echo "  cmake ../.. -GNinja -DCMAKE_BUILD_TYPE=Debug -DDESKTOP_MODE=ON -DBUILD_TESTS=ON -DCMAKE_PREFIX_PATH=\$HOME/Qt/6.10.0/gcc_64"
echo "  ninja"
echo "  cd tests"
echo "  ./steganography_tests"
