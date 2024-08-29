class Apron < Formula
  desc "Numerical abstract domain library"
  homepage "http://apron.cri.ensmp.fr/library/"
  url "https://github.com/antoinemine/apron/archive/refs/tags/v0.9.15.tar.gz"
  sha256 "5778fa1afaf0b36fe6a79989fc4374b0b3ece8a5e46a7ab195440209ccd67b1b"
  revision 2

  depends_on "gmp"
  depends_on "mpfr"
  depends_on "ppl"

  def install
    ENV.deparallelize
    system "./configure --absolute-dylibs --no-strip"
    system "make",
           "APRON_PREFIX=#{prefix}",
           "GMP_PREFIX=#{Formula["gmp"].opt_prefix}",
           "MPFR_PREFIX=#{Formula["mpfr"].opt_prefix}",
           "PPL_PREFIX=#{Formula["ppl"].opt_prefix}",
           "HAS_OCAML=",
           "HAS_OCAMLOPT=",
           "HAS_JAVA=",
           "OCAMLFIND=",
           "HAS_PPL=1",
           "all",
           "install"
    rm Dir[lib/"*.ml", lib/"*.mli", lib/"*.idl"] # Remove ocaml stuff
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <ap_global0.h>
      #include <box.h>

      int main() {
        ap_manager_t* manbox = box_manager_alloc();
        ap_abstract0_t* top = ap_abstract0_top(manbox, 0, 0);
        ap_abstract0_free(manbox, top);
        ap_manager_free(manbox);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-lapron", "-lboxMPQ", "-o", "test"
    system "./test"
  end
end
