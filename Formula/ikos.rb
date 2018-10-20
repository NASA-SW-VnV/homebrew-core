class Ikos < Formula
  include Language::Python::Virtualenv
  desc "Static analyzer for C/C++ based on the theory of Abstract Interpretation"
  homepage "https://github.com/nasa-sw-vnv/ikos"
  url "https://github.com/nasa-sw-vnv/ikos/archive/v2.0.tar.gz"
  sha256 "03a93794651e51e639c47b8ef821f923f7951a11669a7ad3230a68f5f27e1c5f"

  depends_on "cmake" => :build
  depends_on "apron"
  depends_on "boost"
  depends_on "gmp"
  depends_on "llvm@4"
  depends_on "mpfr"
  depends_on "ppl"
  depends_on "python@2" if MacOS.version <= :snow_leopard

  resource "Pygments" do
    url "https://files.pythonhosted.org/packages/71/2a/2e4e77803a8bd6408a2903340ac498cb0a2181811af7c9ec92cb70b0308a/Pygments-2.2.0.tar.gz"
    sha256 "dbae1046def0efb574852fab9e90209b23f556367b5a320c0bcb871c77c3e8cc"
  end

  # Fix for apron 0.9.10
  # Fixed in upstream, remove for next version
  patch :p0, <<~EOS
    --- core/include/ikos/core/domain/numeric/apron.hpp
    +++ core/include/ikos/core/domain/numeric/apron.hpp
    @@ -87,7 +87,7 @@ inline InvPtr inv_ptr(ap_abstract0_t* inv) {

     /// \\returns the size of a ap_abstract0_t
     inline std::size_t dims(ap_abstract0_t* inv) {
    -  return _ap_abstract0_dimension(inv).intdim;
    +  return ap_abstract0_dimension(ap_abstract0_manager(inv), inv).intdim;
     }

     /// \\brief Add some dimensions to a ap_abstract0_t
  EOS

  def install
    venv = virtualenv_create(libexec/"vendor")
    venv.pip_install resources

    mkdir "build" do
      system "cmake",
             "-G", "Unix Makefiles",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DCMAKE_INSTALL_PREFIX=#{prefix}",
             "-DGMP_ROOT=#{Formula["gmp"].opt_prefix}",
             "-DMPFR_ROOT=#{Formula["mpfr"].opt_prefix}",
             "-DPPL_ROOT=#{Formula["ppl"].opt_prefix}",
             "-DAPRON_ROOT=#{Formula["apron"].opt_prefix}",
             "-DCUSTOM_BOOST_ROOT=#{Formula["boost"].opt_prefix}",
             "-DPYTHON_EXECUTABLE=#{libexec}/vendor/bin/python",
             "-DLLVM_CONFIG_EXECUTABLE=#{Formula["llvm@4"].opt_prefix}/bin/llvm-config",
             ".."
      system "make", "install"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>

      int main(int argc, char** argv) {
        int i;
        int a[10];
        for (i = 0; i < 10; i++) {
          a[i] = i;
        }
        printf("%d\\n", a[i - 1]);
        return 0;
      }
    EOS
    output = shell_output("#{bin}/ikos test.c")
    assert_includes output.split("\n"), "The program is SAFE"
  end
end
