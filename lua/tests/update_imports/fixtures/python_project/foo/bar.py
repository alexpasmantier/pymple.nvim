# monolithic
from foo.baz.quux import some_variable
import foo.baz.quux
import foo.baz.quux.something

import foo.baz.quux_wrong


# split
from foo.baz import quux

from foo.baz import (
    something
)

from foo.baz import (
    something,
    quux,
    something_else,
)
