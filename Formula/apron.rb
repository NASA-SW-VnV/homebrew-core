class Apron < Formula
  desc "Numerical abstract domain library"
  homepage "http://apron.cri.ensmp.fr/library/"
  url "http://apron.cri.ensmp.fr/library/apron-0.9.10.tgz"
  sha256 "b108de2f4a8c4ecac1ff76a6d282946fd3bf1466a126cf5344723955f305ec8e"

  depends_on "gmp"
  depends_on "mpfr"
  depends_on "ppl"

  # Fix compiler error about 'invalid operands to binary expression'
  # Upstream commit r1050, remove for next version
  patch :p0, <<~EOS
    --- ppl/ppl_user.cc
    +++ trunk/ppl/ppl_user.cc
    @@ -320,7 +320,12 @@
           exact = false;
         }
         /* singleton */
    -    else r.insert(Constraint(Variable(i)==temp));
    +    else {
    +      /* integerness check */
    +      mpz_class temp2 = mpz_class(temp);
    +      if (temp==temp2) r.insert(Constraint(Variable(i)==temp2));
    +      else exact = false;
    +    }
       }
       return exact;
     }
  EOS

  # Fix linker error
  # Upstream commit r1069, remove for next version
  patch :p0, <<~EOS
    --- products/Makefile
    +++ products/Makefile
    @@ -117,9 +117,9 @@
     	$(AR) rcs $@ $^
     	$(RANLIB) $@
     libap_pkgrid.so: ap_pkgrid.o
    -	$(CXX) $(CXXFLAGS) -shared -o $@ $^ $(LIBS)
    +	$(CXX) $(CXXFLAGS) -shared -o $@ $^ -L../newpolka -lpolkaMPQ $(LIBS)
     libap_pkgrid_debug.so: ap_pkgrid_debug.o
    -	$(CXX) $(CXXFLAGS_DEBUG) -shared -o $@ $^ $(LIBS_DEBUG)
    +	$(CXX) $(CXXFLAGS_DEBUG) -shared -o $@ $^ -L../newpolka -lpolkaMPQ $(LIBS_DEBUG)

     #---------------------------------------
     # C rules
  EOS

  def install
    ENV.deparallelize
    cp "Makefile.config.model", "Makefile.config"
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
