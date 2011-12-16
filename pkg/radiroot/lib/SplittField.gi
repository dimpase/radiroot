#############################################################################
####
##
#W  SplittField.gi            RADIROOT package                Andreas Distler
##
##  Installs the functions to compute the splitting field of a polynomial
##
#H  $Id: SplittField.gi,v 1.4 2008/01/22 11:57:43 gap Exp $
##
#Y  2006
##


#############################################################################
##
#M  SplittingField( <f> )
##
##  Returns the smallest field, that contains the roots of the irreducible,
##  rational polynomial <f> as algebraic extension of the Rationals
##
InstallMethod( SplittingField, "rational polynomials",
[ IsUnivariateRationalFunction and IsPolynomial ],
function( f )
    local splitt;

    if not IsSeparablePolynomial( f ) then
        # make polynomial separable
        f := f / Gcd( f, Derivative( f ) );    
    fi;

    splitt := RR_Zerfaellungskoerper( f, 
                                      rec( roots := [ ],
                                           degs := [ ],
                                           coeffs := [ ],
                                           K := FieldByMatrices([ [[ 1 ]] ]),
                                           H := Rationals ) );

    if Length( splitt.roots[1] ) >= Length( splitt.roots[2] ) then
        # roots as matrices, otherwise linear factors known
        Add( splitt.roots[1], 
             -CoefficientsOfUnivariatePolynomial(f)[Degree(f)]*One(splitt.K)
             -Sum( splitt.roots[1] ) );
        SetRootsAsMatrices( f, splitt.roots[1] );
    fi;

    return splitt.H;
end );


#############################################################################
##
#F  IsomorphicMatrixField( <L> )
##
##  returns a matrix field which is isomorphic to the field <L>
##
InstallGlobalFunction( IsomorphicMatrixField, function( L )
    return Range( IsomorphismMatrixField( L ) );
end );


#############################################################################
##
#O  IsomorphismMatrixField( Rationals )
##
##  installs the value for 'IsomorphismMatrixField' of the Rationals
##
SetIsomorphismMatrixField( Rationals, 
                           MappingByFunction( Rationals,
                                              FieldByMatrices([[[ 1 ]]]),
                                              x -> [[ x ]],
                                              mat -> mat[1][1] ));


#############################################################################
##
#F  RR_BegleitMatrix( <f>, <A> )
##
##  Computes the companion matrix of the polynomial <f> with respect to
##  the field generated by the matrix <A>
##
InstallGlobalFunction( RR_BegleitMatrix, function( f, A )
    local matrix, coeff, blockmat, deg, i, k, l;

    deg := Degree(f);
    coeff := CoefficientsOfUnivariatePolynomial(f);
    matrix := NullMat( deg*Size(A), deg*Size(A), Rationals);

    # create last row
    for i in [ 1..deg ] do
        # matrix, representing the i-th coefficient
        blockmat := -RR_RootInK( A, coeff[i] );
        for k in [1..Size(A)] do
            for l in [1..Size(A)] do
                matrix[(deg-1)*Size(A)+k][(i-1)*Size(A)+l] := blockmat[k][l];
            od;
        od;
    od;

    # fill the secondary diagonal with 1
    for i in [1..(deg-1)] do
        for k in [1..Size(A)] do 
            matrix[(i-1)*Size(A)+k][i*Size(A)+k] := 1;
        od;
    od;
    	
    return matrix;
end );


#############################################################################
##
#F  RR_BlowUpMat, function( <mat>, <n> )
##
##  Computes a matrix that is <n>-times bigger than <mat> and has
##  <mat> on the <n> blocks with size of <mat> at the diagonal
##
InstallGlobalFunction( RR_BlowUpMat, function( mat, n )
    local i, j, k, Mat;

    Mat := NullMat( n * Size(mat), n * Size(mat), Rationals );

    for i in [ 1..n ] do
        for j in [ 1..Size( mat ) ] do
            for k in [ 1..Size( mat ) ] do
                Mat[ (i-1)*Size(mat)+j ][ (i-1)*Size(mat)+k ] := mat[j][k];
            od;
        od;
    od;

    return Mat;
end );


#############################################################################
##
#F  RR_MatrixField( <f>, <mat> )
##
##  Returns the matrixfield that arises from adjoining a root of the
##  polynomial <f> to the matrixfield generated by <mat>
##
InstallGlobalFunction( RR_MatrixField, function( f, mat )
    local A, B;

    # mat as matrix in the supfield
    # mat is deg(f) times on the diagonal 
    A := RR_BlowUpMat( mat, Degree(f) );

    # companion matrix of f with respect to the field generated by mat
    B := RR_BegleitMatrix( f, mat );

    return FieldByMatricesNC( [A, B] );
end );


#############################################################################
##
#F  RR_RootInH( <erw>, <a> )
##
##  The record <erw> contains two isomorphic fields. One generated
##  with AlgebraicExtension and the other as matrixfield. Both are
##  defined by a primitive element. This function transfers the
##  matrix <a> to it's isomorphic symbolic represenation
##
InstallGlobalFunction( RR_RootInH, function( erw, a )
    local coeff, bas;

    # basis {1, primEl, ... , primEl^(n-1)} as matrices
    bas := EquationOrderBasis( erw.K, PrimitiveElement( erw.K ));

    return LinearCombination( Basis( erw.H ), Coefficients( bas, a) );
end ); 
    

#############################################################################
##
#F  RR_RootInK( <primEl>, <coeff> )
##
##  Does the inverse of RR_RootInH; the fieldelement given symbolic
##  by it's external representation <coeff> is transfered in a matrix
##  of the field generated by <primEl>
##
InstallGlobalFunction( RR_RootInK, function( primEl, elm )
    local i, mat;

    mat := NullMat( Size(primEl), Size(primEl), Rationals );
    for i in [1..Size(primEl)] do
        mat := mat +  ExtRepOfObj(elm)[i] * primEl^(i-1);
    od;

    return mat;
end );


#############################################################################
##
#F  RR_Zerfaellungskoerper( <poly>, <erw> )
##
##  Computes the splitting field of the polynomial <poly>. In the
##  record <erw> the field is stored as matrix field as well as in a
##  symbolic represenation generated by
##  AlgebraicExtension. The roots of <poly> are also stored.  
##
InstallGlobalFunction( RR_Zerfaellungskoerper, function( poly, erw )
    local matA,matB,faktoren,i,f,minpol,roots,primEl, map;

    # catch trivial case
    if Degree( poly ) = 1 then 
        erw.roots := [ [ ], [ ] ];
        return erw;
    fi;

    # Splitting field already known
    if not IsBound( erw.unity ) and HasSplittingField( poly ) then
        erw.H := SplittingField( poly );
        erw.K := IsomorphicMatrixField( erw.H );
        # roots will be needed in any further computation
        erw.roots := [ ShallowCopy( RootsAsMatrices( poly ) ), [] ];
        erw.degs := RR_DegreeConclusion( Basis(erw.K), erw.roots[1] );
        Remove( erw.roots[1] );
        erw.coeffs := Filtered(Coefficients(Basis(erw.K),
                                            PrimitiveElement(erw.K)),
                               i -> i <> 0 );

        return erw;   
    fi;

    roots := [ ];

    # repeat until <poly> factors in linear polynomials
    while Length(erw.roots) + Length(roots) + 1 < Degree(poly) do
	
        # factors <poly> over the latest <erw.H>	
	faktoren := FactorsPolynomialAlgExt( erw.H, poly );;
	Info( InfoRadiroot, 4, "    Factorization of polynomial:\n",
              faktoren );
    	f := faktoren[ Length( faktoren ) ];
        if Degree( f ) = 1 then break; fi;

        roots := RR_Roots( [ erw.roots, roots, 
                             List( Filtered( faktoren, f -> Degree( f ) = 1 ), 
                                   f -> 
                                   -CoefficientsOfUnivariatePolynomial(f)[1])],
                           erw );

	erw.K := RR_MatrixField( f, PrimitiveElement( erw.K ) );
	Add( erw.degs, Degree(f) );
        SetDegreeOverPrimeField( erw.K, Product( erw.degs ));
        Info( InfoRadiroot, 3,"        Degree of the extension: ", Degree(f) );

	matA := GeneratorsOfField( erw.K )[ 1 ];;
	matB := GeneratorsOfField( erw.K )[ 2 ];;

        # bring the list of roots up-to-date
	for i in [ 1..Length(erw.roots) ] do
	    erw.roots[i] := RR_BlowUpMat( erw.roots[i], Degree( f ) );
	od;
	for i in [ 1..Length(roots) ] do
	    roots[i] := RR_BlowUpMat( roots[i], Degree( f ) );
	od;
        if IsBound( erw.unity ) then 
            erw.unity := RR_BlowUpMat( erw.unity, Degree( f ) );
        fi;

        Info( InfoRadiroot, 4, "            Adjoined root:\n", matB );
	Add( erw.roots, matB );

        Info( InfoRadiroot, 3, "        Searching for a primitive element" );
        primEl := Sum([1..Length(erw.roots)], i -> i * erw.roots[i]);
        if IsBound( erw.unity ) then
            primEl := primEl+erw.unity;
        fi;
        minpol := MinimalPolynomial( Rationals, primEl );
        if Degree( minpol ) = Product( erw.degs ) then
            SetPrimitiveElement( erw.K, primEl );
            SetDefiningPolynomial( erw.K, minpol );
            Add( erw.coeffs, Length( erw.roots ) );
        else
            for i in [ Minimum( 2 * [ Length( erw.degs )-1, 1 ] )..99 ] do
                minpol := MinimalPolynomial( Rationals, i * matA + matB );
                if Degree( minpol ) = Product( erw.degs ) then
                    SetPrimitiveElement( erw.K, i * matA + matB );
                    SetDefiningPolynomial( erw.K, minpol );
                    erw.coeffs := Flat( [ i * erw.coeffs, 1 ] ); 
		    break;
	        fi;
            od;
        fi;

        erw.H := AlgebraicExtension( Rationals, minpol );
        Info( InfoRadiroot, 3, "    ", minpol, " is defining polynomial.");
    od;
    erw.roots := [ Concatenation( erw.roots, roots ),
                   List( faktoren, f -> -Value( f, 0 ) ) ];
    if IsBound( erw.unity ) then
        erw.degs := erw.degs{[ 2..Length(erw.degs) ]};
    fi;

    Info( InfoRadiroot, 3, "        Composition of the primitive element: ",
                           erw.coeffs );
    map := MappingByFunction( erw.H, erw.K, 
                    x -> RR_RootInK( PrimitiveElement( erw.K ) ,x ),
                    mat -> RR_RootInH( rec( K := erw.K, H := erw.H), mat ));
    SetIsomorphismMatrixField( erw.H, map );
    SetSplittingField( poly, erw.H );

    return erw;
end );


#############################################################################
##
#F  RR_SplittField( <poly>, <m> )
##
##  Calls the function RR_Zerfaellungskoerper for the polynomial <poly> with
##  special initial values. The splitting field is constructed over a
##  cyclotomic field.
##
InstallGlobalFunction( RR_SplittField, function( poly, m )
    local erw, cyclopol;

    cyclopol := CyclotomicPolynomial(Rationals, m);

    erw := rec( roots := [ ], degs := [ Degree(cyclopol) ], coeffs := [ ],
                K := RR_MatrixField( cyclopol, [[ 1 ]]),
                H := AlgebraicExtension( Rationals, cyclopol ));
    erw.unity := PrimitiveElement( erw.K );

    erw := RR_Zerfaellungskoerper( poly, erw );;

    return erw;
end );


#############################################################################
##
#E












