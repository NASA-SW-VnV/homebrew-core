class Ikos < Formula
  include Language::Python::Virtualenv
  desc "Static analyzer for C/C++ based on the theory of Abstract Interpretation"
  homepage "https://github.com/nasa-sw-vnv/ikos"
  url "https://github.com/nasa-sw-vnv/ikos/releases/download/v2.1/ikos-2.1.tar.gz"
  sha256 "bd5e75a2a94fafc3d1cd01eb6541da458a10c7674e7ae29eb211642c526f1407"

  depends_on "cmake" => :build
  depends_on "apron"
  depends_on "boost"
  depends_on "gmp"
  depends_on "llvm@7"
  depends_on "mpfr"
  depends_on "ppl"
  depends_on "python@2" if MacOS.version <= :snow_leopard

  resource "Pygments" do
    url "https://files.pythonhosted.org/packages/63/a2/91c31c4831853dedca2a08a0f94d788fc26a48f7281c99a303769ad2721b/Pygments-2.3.0.tar.gz"
    sha256 "82666aac15622bd7bb685a4ee7f6625dd716da3ef7473620c192c0168aae64fc"
  end

  def install
    venv = virtualenv_create(libexec/"vendor")
    venv.pip_install resources

    xy = Language::Python.major_minor_version "python"
    pth_contents = "import site; site.addsitedir('#{lib}/python#{xy}/site-packages')\n"
    (libexec/"vendor/lib/python#{xy}/site-packages/homebrew_deps.pth").append_lines pth_contents

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
             "-DLLVM_CONFIG_EXECUTABLE=#{Formula["llvm@7"].opt_prefix}/bin/llvm-config",
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
