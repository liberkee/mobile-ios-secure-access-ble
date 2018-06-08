# SecureAccessBLE

## Description
Framework for communicating with the SecureAccess BLE hardware.

## Prerequisites
* [Xcode 9.4](https://developer.apple.com/xcode/ide/)
* [CocoaPods](https://cocoapods.org)

## License
Copyright 2018 Huf Secure Mobile GmbH

The software contained within this package, including all enclosed library releases (Android Archive files, *.aar), documentation and source files ("the software") is provided solely for the purpose of evaluation of Huf Secure Mobile GmbH ("HSM") software, hardware and services by organizations or individuals directly and explicitly authorized by HSM to receive and evaluate this software. Any commercial application or redistribution is prohibited. The software remains the sole intellectual property of HSM.


THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Dependencies
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - [zlib License](https://github.com/krzyzanowskim/CryptoSwift/blob/master/LICENSE)

## Usage
### Manually
Since `SecureAccessBLE` depend on `CryptoSwift`, you will first need to install the dependency.
1. Install `CryptoSwift` by following the instruction [here](https://github.com/krzyzanowskim/CryptoSwift#installation)
2. Add `SecureAccessBLE.framework` to your project by simply dragging in into Xcode.
3. Add `SecureAccessBLE.framework` to embedded binaries section of your App target.

### Via cocoapods
SecureAccessBLE provides a `.podspec` file which allows to be added via CocoaPods. Add following to your app target in the podfile:

```ruby
pod 'SecureAccessBLE', :path => 'PATH_TO_FRAMEWORK'
```
Since the framework is referenced locally, it will appear in `Development Pods` group in the Xcode Workspace.
