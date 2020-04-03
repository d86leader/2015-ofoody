#
#==============================================================================
#
#         FILE: Auth.pm
#
#  DESCRIPTION: O'Foody Authenticate Module
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Vladislav A. Retivykh (var), firolunis@riseup.net
# ORGANIZATION: keva
#      VERSION: 0.1
#      CREATED: 05/14/2015 07:09:12 PM
#     REVISION: ---
#==============================================================================

package Auth;

use strict;
use warnings FATAL => 'all';
use utf8;

use Db;

my $LEGACY = 0;
eval "use Digest::SHA1; 1;" or $LEGACY = 1;

my $SALT = 'SIBIRCTF';
my %TABLES = (
    'USERS' => 'USERS'
);

#===  FUNCTION  ===============================================================
#         NAME: _encode
#      PURPOSE: Encoding strings
#   PARAMETERS: String
#      RETURNS: Encoded string
#  DESCRIPTION: Encode string
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub _encode {
    my $string = shift;
    my $encoded_string = $string . $SALT;
    if (not $LEGACY) {
        my $sha1 = Digest::SHA1->new;
        $sha1->add($encoded_string);
        $encoded_string = $sha1->b64digest;
    }
    return $encoded_string;
}

#===  FUNCTION  ===============================================================
#         NAME: _random_string
#      PURPOSE: Generating random strings
#   PARAMETERS: Length
#      RETURNS: Random string
#  DESCRIPTION: Generate random string
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub _random_string {
    my $length = shift;
    my @chars = ("A".."Z", "a".."z");
    my $string = '';
    if ($length) {
        $string .= $chars[rand @chars] for 1..$length;
    } else {
        $string = '';
    }
    return $string;
}


#===  FUNCTION  ===============================================================
#         NAME: signup
#      PURPOSE: User registration
#   PARAMETERS: {POST data}
#      RETURNS: Message
#  DESCRIPTION: Register users
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub signup {
    my %post_data = %{(shift)} or return 0;
    my %username = ('username' => $post_data{'username'});
    my @check_user = Db::select(
        $TABLES{'USERS'},
        \%username
    );
    my $response;
    if (@check_user) {
        $response = "User $post_data{'username'} already exists";
    } else {
        my @values = (
            $post_data{'username'},
            $post_data{'review'},
            $post_data{'ccn'},
            $post_data{'address'},
            $post_data{'password'}
        );
        if (Db::insert($TABLES{'USERS'}, \@values)) {
            $response = "User $post_data{'username'} was registered";
        } else {
            $response = "Something went wrong";
        }
    }
    return $response;
}

#===  FUNCTION  ===============================================================
#         NAME: login
#      PURPOSE: User login
#   PARAMETERS: {POST data}
#      RETURNS: [Message, Username, Session cookie]
#  DESCRIPTION: Handle users login
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub login {
    my %post_data = %{(shift)} or return 0;
    my %check_data = (
        'username' => $post_data{'username'},
        'password' => $post_data{'password'}
    );
    my @check_user = Db::select(
        $TABLES{'USERS'},
        \%check_data
    );
    my @response;
    if (@check_user) {
        push @response, "You have been successfully logged in";
        push @response, 'username=' . "$post_data{'username'}";
        push @response, 'session=' . _encode($post_data{'username'});
    } else {
        push @response, "Wrong Name/Password";
    }
    return @response;
}

#===  FUNCTION  ===============================================================
#         NAME: logout
#      PURPOSE: User logout
#   PARAMETERS: ---
#      RETURNS: [Username, Session cookie]
#  DESCRIPTION: Handle users logout
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub logout {
    my @response;
    push @response, 'username=-; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    push @response, 'session=-; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    return @response;
}

#===  FUNCTION  ===============================================================
#         NAME: restore
#      PURPOSE: Restoring passwords
#   PARAMETERS: {POST data}
#      RETURNS: Message
#  DESCRIPTION: Restore user password
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub restore {
    my %post_data = %{(shift)} or return 0;
    my %check_data = (
        'username'  => $post_data{'username'},
        'ccn'       => $post_data{'ccn'}
    );
    my @check_user = Db::select(
        $TABLES{'USERS'},
        \%check_data
    );
    my $response;
    if (@check_user) {
        my $new_password = _random_string(10);
        Db::update(
            $TABLES{'USERS'},
            \%post_data,
            {'password' => $new_password}
        );
        $response = "Your new password is $new_password";
    } else {
        $response = "Wrong Name/Credit card number";
    }
    return $response;
}

#===  FUNCTION  ===============================================================
#         NAME: passwd
#      PURPOSE: Changing passwords
#   PARAMETERS: {POST data}
#      RETURNS: Message
#  DESCRIPTION: Change user password
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub passwd {
    my %post_data = %{(shift)} or return 0;
    my %check_data = (
        'username'  => $post_data{'username'},
        'password'  => $post_data{'password'}
    );
    my @check_user = Db::select(
        $TABLES{'USERS'},
        \%check_data
    );
    my $response;
    if (@check_user) {
        my $new_password = $post_data{'newpassword'};
        Db::update(
            $TABLES{'USERS'},
            \%check_data,
            {'password' => $new_password}
        );
        $response = "Your new password is $new_password";
    } else {
        $response = "Wrong password";
    }
    return $response;
}

#===  FUNCTION  ===============================================================
#         NAME: check
#      PURPOSE: Checking users
#   PARAMETERS: Username, Session
#      RETURNS: Boolean
#  DESCRIPTION: Check user rights
#       THROWS: ---
#     COMMENTS: ---
#     SEE ALSO: ---
#==============================================================================
sub check {
    my $username = shift or return 0;
    my $session = shift or return 0;
    my %check_data = (
        'username'  => $username,
    );
    my @check_user = Db::select(
        $TABLES{'USERS'},
        \%check_data
    );
    return _encode($check_user[0][1]) eq $session;
}

1;
