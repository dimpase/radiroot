#############################################################################
####
##
#W  Radicals.gi               RADIROOT package                Andreas Distler
##
##  Installation file for the main function of the RADIROOT package
##
#H  @(#)$Id: Radicals.gi,v 1.0 2004/08/21 14:38:01 gap Exp $
##
#Y  2004
##


#############################################################################
##
#F  RR_RootOfUnity( <erw>, <ord> )
##
##  Computes a <ord>-th root of unity built up on the roots of unity
##  that already exists in the field of the record <erw>
##
InstallGlobalFunction( RR_RootOfUnity, function( erw, ord )
    local i, unity, faktor;

    unity := One( erw.K );
    for i in DuplicateFreeList( Factors( ord ) ) do
        # erster Faktor des i.-Kreisteilungspolynoms in H
        faktor := FactorsPolynomialKant( CyclotomicPolynomial( Rationals, i ),
                                        erw.H )[ 1 ];
	if Degree( faktor ) = 1 then 
	    unity := unity * RR_RootInK( erw.primEl, 
	        -CoefficientsOfUnivariatePolynomial( faktor )[ 1 ]);
	else
	    unity := unity * E( i );
	fi;
    od;

    return unity;
end );


#############################################################################
##
#M  IsSolvablePolynomial( <f> )
#M  IsSolvable( <f> )
##
##  Determines wether the polynomial <f> is solvabel, e. g. wether its
##  Galois-group is solvable
##
InstallMethod( IsSolvablePolynomial,
[ IsUnivariatePolynomial ],
function( f )

    if ForAny( CoefficientsOfUnivariatePolynomial(f),
               c -> not c in Rationals ) then TryNextMethod( ); fi;

    return ForAll( Factors(f),
                   ff -> IsSolvableGroup( TransitiveGroup( Degree(ff),
                                          GaloisType(ff) ) ) );
end );

InstallMethod( IsSolvable, [ IsPolynomial ], IsSolvablePolynomial );

#############################################################################
##
#F  RootsOfPolynomialAsRadicals( <poly> )
##
##  For the irreducible, rational polynomial <poly> a representation
##  of the roots as radicals is computed if this is possible, e. g. if
##  the Galois-group of <poly> is solvable. The function stores the
##  result as a Tex-readable string in a file
##
InstallGlobalFunction( RootsOfPolynomialAsRadicals, function( poly )
    local galgrp, erw, elements, lcm, conj, bas;

    # Irreduziblitaet pruefen
    if not IsIrreducible( poly ) then
        return "Polynomial have to be irreducible.";
    fi;

    # Aufloesbarkeit pruefen
    if not IsSolvable( poly ) then
        return "Polynomial is not solvable.";
    fi; 

    # Initialisierung, Koerper mit Einheitswurzeln
    erw := rec( roots := [], degs := [], primEl := [[ 1 ]], H := Rationals );

    erw := RR_Zerfaellungskoerper( poly, erw );
    galgrp := RR_ConstructGaloisGroup( erw );
    erw.unity := RR_RootOfUnity( erw, Order( galgrp ) );

    elements := RR_CyclicElements( erw, CompositionSeries( galgrp ) );;
    bas := RR_Radikalbasis( erw, elements );;
    RR_NstInDatei( SolutionMat( List( bas[1], Flat ), Flat(erw.roots[1]) ),
                   bas[2] ); 

    return [ elements, erw ];
end );


#############################################################################
##
#E









