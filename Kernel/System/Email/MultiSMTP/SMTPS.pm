# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# Changes Copyright (C) 2011-2017 Perl-Services.de, http://perl-services.de
# Changes Copyright (C) 2017 WestDevTeam, http://westdev.by
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSMTP::SMTPS;

use strict;
use warnings;

use Net::SMTP;

use parent 'Kernel::System::Email::MultiSMTP::SMTP';

our @ObjectDependencies = (
    'Kernel::System::Log',
);

# Use Net::SSLGlue::SMTP on systems with older Net::SMTP modules that cannot handle SMTPS.
BEGIN {
    if ( !defined &Net::SMTP::starttls ) {
        ## nofilter(TidyAll::Plugin::OTRS::Perl::Require)
        ## nofilter(TidyAll::Plugin::OTRS::Perl::SyntaxCheck)
        require Net::SSLGlue::SMTP;
    }
}

sub _Connect {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(MailHost FQDN)) {
        if ( !$Param{$_} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # Remove a possible port from the FQDN value
    my $FQDN = $Param{FQDN};
    $FQDN =~ s{:\d+}{}smx;

    # set up connection connection
    my $SMTP = Net::SMTP->new(
        $Param{MailHost},
        Hello           => $FQDN,
        Port            => $Param{SMTPPort} || 465,
        Timeout         => 30,
        Debug           => $Param{SMTPDebug},
        SSL             => 1,
        SSL_verify_mode => 0,
    );

    return $SMTP;
}

1;
