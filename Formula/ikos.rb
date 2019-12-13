class Ikos < Formula
  include Language::Python::Virtualenv
  desc "Static analyzer for C/C++ based on the theory of Abstract Interpretation"
  homepage "https://github.com/nasa-sw-vnv/ikos"
  url "https://github.com/nasa-sw-vnv/ikos/releases/download/v3.0/ikos-3.0.tar.gz"
  sha256 "bd42e84061c207ea7ca7f0c7d7aafa3cce72e951d33953b0ed8d68133b17c8b6"

  depends_on "cmake" => :build
  depends_on "apron"
  depends_on "boost"
  depends_on "gmp"
  depends_on "llvm@9"
  depends_on "mpfr"
  depends_on "ppl"
  depends_on "python"

  resource "Pygments" do
    url "https://files.pythonhosted.org/packages/7e/ae/26808275fc76bf2832deb10d3a3ed3107bc4de01b85dcccbe525f2cd6d1e/Pygments-2.4.2.tar.gz"
    sha256 "881c4c157e45f30af185c1ffe8d549d48ac9127433f2c380c24b84572ad66297"
  end

  def install
    venv = virtualenv_create(libexec/"vendor", "python3")
    venv.pip_install resources

    xy = Language::Python.major_minor_version "python3"
    pth_contents = "import site; site.addsitedir('#{lib}/python#{xy}/site-packages')\n"
    (libexec/"vendor/lib/python#{xy}/site-packages/homebrew_deps.pth").write pth_contents

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
             "-DLLVM_CONFIG_EXECUTABLE=#{Formula["llvm@9"].opt_prefix}/bin/llvm-config",
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
