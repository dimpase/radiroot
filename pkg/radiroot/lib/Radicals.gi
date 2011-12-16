#############################################################################
####
##
#W  Radicals.gi               RADIROOT package                Andreas Distler
##
##  Installation file for the main function of the RADIROOT package
##
#H  @(#)$Id: Radicals.gi,v 1.5 2008/01/22 11:57:43 gap Exp $
##
#Y  2006
##


#############################################################################
##
#F  RR_RootOfUnity( <erw>, <ord> )
##
##  Computes a <ord>-th root of unity built up on the roots of unity
##  that already exists in the field of the record <erw>
##
InstallGlobalFunction( RR_RootOfUnity, function( erw, ord )
    local i, unity, cond, faktor, m;

    Info( InfoRadiroot, 2, "    Finding root of unity" );
    unity := One( erw.K );
    if ord = 1 then
        return unity;
    fi;
    cond := 1;
    m := 1;
    for i in DuplicateFreeList( Factors( ord ) ) do
        # first factor of the i-th cyclotomic polynomial in H
        faktor:=FactorsPolynomialAlgExt(erw.H,
                                        CyclotomicPolynomial(Rationals,i))[1];
        Info( InfoRadiroot, 3,"        Cyclotomic polynomial factor: ",
                              faktor );

        if Degree( faktor ) = i-1 then
	    cond := cond * i; #unity := unity * E( i );
            Info( InfoRadiroot, 4, "            Adjoining ", i,
                                   "-th root of unity" );
	elif Degree( faktor ) = 1 then
	    unity := unity * Image( IsomorphismMatrixField( erw.H ),
                                    -Value( faktor, 0 ) );
            Info( InfoRadiroot, 4, "            Calculate ", i,
                                   "-th root of unity" );
        else
            m := i * m; 
	fi;
    od;

    if  m = 1 then
        return E( cond ) * unity;
    else
        return m * Order( unity );
    fi;
end );


#############################################################################
##
#M  IsSolvablePolynomial( <f> )
#M  IsSolvable( <f> )
##
##  Determines whether the rational polynomial <f> is solvable, e. g. whether
##  its Galois group is solvable
##
InstallMethod( IsSolvablePolynomial, "for a rational polynomial", 
[ IsUnivariateRationalFunction and IsPolynomial ], 0,
function( f )

    f := RR_SimplifiedPolynomial( f );
    return ForAll( Filtered( List( Factors(f), RR_SimplifiedPolynomial ),
                             ff -> Degree(ff) <> 1 ),
                   ff -> IsSolvableGroup( TransitiveGroup( Degree(ff),
                                          GaloisType(ff) ) ) );
end );

InstallMethod( IsSolvable, "rational polynomials", [ IsPolynomial ],
               IsSolvablePolynomial );

#############################################################################
##
#M  IsSeparablePolynomial( <f> )
##
##  Determines whether the rational polynomial <f> is separable, e.g. whether
##  it has single roots only
##
InstallMethod( IsSeparablePolynomial, "for rational polynomial", 
[ IsUnivariateRationalFunction and IsPolynomial ], 0,
function( f )
    if Degree(Gcd( f, Derivative( f ))) = 0 then return true; fi;
    return false;
end );

#############################################################################
##
#M  RootsAsMatrices( <f> )
##
##  return a list of matrices with minimal polynomial <f>. The field 
##  generated by the matrices is a splitting field of <f>. The dimension of 
##  the matrices is equal to the dimension of the splitting field over the
##  Rationals
##
InstallMethod( RootsAsMatrices, "rational polynomials", 
[ IsUnivariateRationalFunction and IsPolynomial ], function( f )
    local L, roots, erw;

    if not IsSeparablePolynomial( f ) then
        Info( InfoWarning, 1, "polynomial is not separable, list contains every root only once" );
        # make polynomial separable
        f := f / Gcd( f, Derivative( f ) );    
    fi;

    if HasSplittingField( f ) then
        L := IsomorphicMatrixField( SplittingField( f ));
        roots := Filtered(Basis(L), mat -> Value(f,mat) = 0*One(L));
        if Length( roots ) < Degree( f ) - 1 then
            erw := rec( H := SplittingField( f ), K := L );
            roots:=RR_Roots([[],roots, 
                             List(FactorsPolynomialAlgExt(SplittingField(f),f),
                                  faktor -> -Value( faktor, 0 ) )], 
                            erw);;
        fi;
    else
        erw := RR_Zerfaellungskoerper(f, rec( roots := [ ],
                                              degs := [ ],
                                              coeffs := [ ],
                                              K:=FieldByMatrices([ [[ 1 ]] ]),
                                              H:=Rationals ));;
        L := erw.K;
        roots := RR_Roots( [ [ ], erw.roots[1], erw.roots[2] ], erw );;
     fi;

    Add( roots, 
         -CoefficientsOfUnivariatePolynomial( f )[Degree( f )]*One(L)
         -Sum( roots ) );

    return roots;
end );


#############################################################################
##
#F  RR_Roots( <roots>, <erw> )
##
##  The elements in the list of lists <roots> are in various forms. They are
##  transfered in a matrix representation and returned as duplicate free list
##
InstallGlobalFunction( RR_Roots, function( roots, erw )
    local i, root, B;    

    # Test whether there are already enough roots as matrices
    if Length(roots[1]) + Length(roots[2]) >= Length(roots[3]) then
        return roots[2];
    fi;

    B := EquationOrderBasis( erw.K, PrimitiveElement( erw.K ));

    # kick out known symbolic roots
    for root in Concatenation(roots[1], roots[2]) do
        root := LinearCombination( Basis( erw.H ), Coefficients( B, root ) );
        roots[3] := Difference( roots[3], [ root ] );
    od;

    # compute the other roots
    if roots[1] = [ ] then Unbind(roots[3][Length(roots[3])]); fi; 
    for root in roots[3] do
        Info(InfoRadiroot,3,"        Constructing ",Length(roots[2]),". root");
        Add( roots[2], LinearCombination( B, ExtRepOfObj( root )));
    od;
 
    return roots[2];
end );


#############################################################################
##
#F  RR_SimplifiedPolynomial( <f> )
##
##  returns the polynomial g(x) with g(x^n) = f(x-a) with greatest possible n
##  for the polynomial <f>
##
InstallGlobalFunction( RR_SimplifiedPolynomial, function( f )
    local deg, coeff, gcd, poly;

    deg := Degree( f );

    poly := f / LeadingCoefficient( f );
    poly := Value( poly, UnivariatePolynomial( Rationals,
        [-CoefficientsOfUnivariatePolynomial(poly)[deg] / deg, 1] ) );
    coeff := CoefficientsOfUnivariatePolynomial( poly );
    gcd := Gcd(Filtered( [0..Degree(f)], i -> not coeff[i+1] = 0));
    if gcd = 1 then
        return f / LeadingCoefficient(f);
    fi;

    return UnivariatePolynomial(Rationals,
                                List([0..deg/gcd], i -> coeff[i*gcd+1]));
end );


#############################################################################
##
#F  RootsOfPolynomialAsRadicals( <f>, [ <mode> , <file> ] )
#F  RootsOfPolynomialAsRadicalsNC( <f>, [ <mode> , <file> ] )
##
##  For the irreducible, rational polynomial <f> a representation of the
##  roots as radicals is computed if this is possible, e. g. if the
##  Galois group of <f> is solvable.
##
InstallGlobalFunction( RootsOfPolynomialAsRadicals, function( arg )

    local f;

    f := arg[1];
 
    if Length( arg ) >= 2 and arg[2] = "off" then
        if not IsSeparablePolynomial( f ) then 
            Error( "f must be separable" );
        fi;
        CallFuncList( RootsOfPolynomialAsRadicalsNC, arg );

    else
        # irreducibility test
        if not IsIrreducible( f ) then
            Error( "f must be irreducible" );
        fi;

        # solvibility test
        if not IsSolvable( f ) then
            Info( InfoRadiroot, 1, "Polynomial is not solvable." );
            Info( InfoRadiroot, 3, "        GaloisType is ", GaloisType( f ) );
            return fail;
        fi; 

        Info( InfoRadiroot, 3, "        GaloisType is ", GaloisType( f ) );
        Info( InfoRadiroot, 2, "    Galoisgroup is ",
                               TransitiveGroup( Degree( f ), GaloisType( f )));

        return  CallFuncList( RootsOfPolynomialAsRadicalsNC, arg );
    fi;
end );


InstallGlobalFunction( RootsOfPolynomialAsRadicalsNC, function( arg )
    local erw,elements,lcm,conj,bas,file,dir,poly,B,fix,compser,f,mode,path;

    f := arg[1];

    if 1 = Length( arg ) then
        mode := "dvi";
    else
        mode := arg[2];
    fi;

    while not mode in [ "off", "dvi", "maple", "latex" ] do
        Error( "<mode> has to be a valid option" );
    od;
    
    # normed, simplified polynomial
    if mode <> "off" then
        # irreducibility test
        if not IsIrreducible( f ) then
            Error( "f must be irreducible" );
        fi;
        poly := RR_SimplifiedPolynomial( f );
        Info( InfoRadiroot, 2, "    Normed, simplified Polynomial: ", poly );
    else
        if LeadingCoefficient( f ) <> 1 then
            Error( "f must be a normed polynomial" );
        fi;
        poly := f;
    fi;
   
    Info( InfoRadiroot, 2, "    Construction of the splitting field" );
    erw := RR_Zerfaellungskoerper( poly, rec( roots := [ ],
                                              degs := [ ],
                                              coeffs := [ ],
                                              K:=FieldByMatrices([ [[ 1 ]] ]),
                                              H:=Rationals ));;

    # get all roots, set a basis of the primitive element
    erw.roots := RR_Roots( [ [], erw.roots[1], erw.roots[2] ], erw );;
    Add( erw.roots, 
         -CoefficientsOfUnivariatePolynomial(poly)[Degree(poly)]*One(erw.K)
         -Sum( erw.roots ) );
    SetRootsAsMatrices( poly, erw.roots );

    # get structure of primitive element to use RR_Produkt
    erw.coeffs := Filtered(Coefficients(Basis(erw.K),PrimitiveElement(erw.K)),
                           i -> i <> 0 );

    # for mode "off" it remains to compute the Galois group
    if mode = "off" then
        if not HasGaloisGroupOnRoots( poly ) then
            erw.unity := 1;
            erw.galgrp := RR_ConstructGaloisGroup( erw );
            SetGaloisGroupOnRoots( poly, erw.galgrp );
        fi;
        return;
    fi;

    # try to find root of unity, if fail start all over
    erw.unity := RR_RootOfUnity( erw, DegreeOverPrimeField(erw.K) );
    if IsInt(erw.unity) then 
        erw := RR_SplittField(poly, erw.unity );
        # need roots in bigger field
        erw.roots := RR_Roots( [ [], erw.roots[1], erw.roots[2] ], erw );;
        Add(erw.roots, 
            -CoefficientsOfUnivariatePolynomial(poly)[Degree(poly)]
            *One(erw.K) - Sum( erw.roots ) );
        erw.coeffs := Filtered( Coefficients( Basis( erw.K ),
                                              PrimitiveElement( erw.K )),
                                i -> i <> 0 );
        erw.galgrp := RR_ConstructGaloisGroup( erw );
    elif HasGaloisGroupOnRoots( poly ) then
        erw.galgrp := GaloisGroupOnRoots( poly );
    else
        erw.galgrp := RR_ConstructGaloisGroup( erw );
        SetGaloisGroupOnRoots( poly, erw.galgrp );
    fi;

    Info( InfoRadiroot, 2, "    Galoisgroup as PermGrp is ", erw.galgrp );

    if not IsSolvable( erw.galgrp ) then
        Info( InfoRadiroot, 1, "Polynomial is not solvable." );
        return fail;
    fi; 

    Info(InfoRadiroot,4,"            h := Lcm( Order( Galoisgroup ) ) = ",
                        Product(Unique(Factors(Order(erw.galgrp)))) );
    if IsDiagonalMat( erw.unity ) then
        Info( InfoRadiroot, 3, 
              "        no root of unity in the splitting field"); 
        compser := CompositionSeries( erw.galgrp );
    elif Length( erw.degs ) <> Length( erw.coeffs ) then
        compser := CompositionSeries( erw.galgrp );
    else
        fix := Filtered(AsList(erw.galgrp), 
                        p -> RR_Produkt(erw, erw.unity, p) = erw.unity);
        compser := RR_CompositionSeries( erw.galgrp, AsGroup( fix ));
    fi; 
    erw.K!.cyclics := RR_CyclicElements( erw, compser );;
    Info( InfoRadiroot, 2, "    computed cyclic elements" );

    if 3 = Length( arg ) then
        file := arg[3];
        dir := DirectoryCurrent( );
    else
        dir := DirectoryTemporary( );
        file := "Nst";
    fi;
    if mode <> "maple" then
        if IsExistingFile( Concatenation( file, ".tex" ) ) then
            Error( file, ".tex already exists" );
        fi;
        path := RR_TexFile( f, erw, erw.K!.cyclics, dir, 
                            Concatenation( file, ".tex" ) );
        if mode = "dvi" then
            RR_Display( file, dir );
        fi;
    else
        if IsExistingFile( file ) then
            Error( file, " already exists" );
        fi;
        path := RR_MapleFile( f, erw, erw.K!.cyclics, Filename(dir,file));
    fi;
    return path;

end );


#############################################################################
##
#E









