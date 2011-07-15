# --
# Kernel/System/Email/MultiSMTP.pm - the global email send module
# Copyright (C) 2001-2010 OTRS AG, http://otrs.org/
# --
# $Id: MultiSMTP.pm,v 1.29 2010/01/12 15:55:38 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Email::MultiSMTP;

use strict;
use warnings;

use Kernel::System::EmailParser;
use Kernel::System::MultiSMTP;
use Kernel::System::Email::SMTP;
use Kernel::System::Email::SMTPS;
use Kernel::System::Email::SMTPTLS;
use Kernel::System::Email::MultiSMTP::SMTP;
use Kernel::System::Email::MultiSMTP::SMTPS;
use Kernel::System::Email::MultiSMTP::SMTPTLS;


use vars qw($VERSION);
$VERSION = qw($Revision: 1.29 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check all needed objects
    for (qw(ConfigObject LogObject EncodeObject MainObject DBObject TimeObject)) {
        die "Got no $_" if ( !$Self->{$_} );
    }

    # create needed object
    $Self->{MSMTPObject}  = Kernel::System::MultiSMTP->new( %Param );
    $Self->{ParserObject} = Kernel::System::EmailParser->new(
        %{$Self},
        Mode  => 'Standalone',
        Debug => 0,
    );

    return $Self;
}

sub Check {
    return (Successful => 1, MultiSMTP => shift ); 
}

sub Send {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Header Body ToArray)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log( Priority => 'error', Message => "Need $_!" );
            return;
        }
    }

    my $SMTPObject;
    if ( !$Param{From} ) {

        # use standard SMTP module as fallback
        my $Module  = $Self->{ConfigObject}->Get('MultiSMTP::Fallback');
        $SMTPObject = $Module->new( %{$Self} );
        $SMTPObject->Send( %Param );
        return;
    }

    my $PlainFrom = $Self->{ParserObject}->GetEmailAddress(
        Email => $Param{From},
    );

    my %SMTP = $Self->{MSMTPObject}->SMTPGetForAddress(
        Address => $PlainFrom,
    );

    if ( !%SMTP ) {

        # use standard SMTP module as fallback
        my $Module  = $Self->{ConfigObject}->Get('MultiSMTP::Fallback');
        $SMTPObject = $Module->new( %{$Self} );
        $SMTPObject->Send( %Param );
        return;
    }

    $SMTP{Password} = $SMTP{PasswordDecrypted};

    my $Module  = 'Kernel::System::Email::MultiSMTP::' . $SMTP{Type};
    $SMTPObject = $Module->new( %{$Self}, %SMTP );

    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => "Use MultiSMTP $Module",
    );

    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => sprintf "Use SMTP %s/%s (%s)", $SMTP{Host}, $SMTP{User}, $SMTP{ID},
    );

    return if !$SMTPObject;
    
    $SMTPObject->Send( %Param );

    return 1;
}

1;
