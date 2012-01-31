
package mx.messaging.messages
{

import flash.utils.IDataOutput;
import flash.utils.IExternalizable;

[RemoteClass(alias="DSC")]

/**
 * A special serialization wrapper for CommandMessage. This wrapper is used to
 * enable the externalizable form of an CommandMessage for serialization. The
 * wrapper must be applied just before the message is serialized as it does not
 * proxy any information to the wrapped message.
 * 
 * @private
 */
public class CommandMessageExt extends CommandMessage implements IExternalizable
{
    //--------------------------------------------------------------------------
    //
    // Constructor
    // 
    //--------------------------------------------------------------------------

    public function CommandMessageExt(message:CommandMessage=null)
    {
        super();
        _message = message;
    }

    override public function writeExternal(output:IDataOutput):void
    {
        if (_message != null)
            _message.writeExternal(output);
        else
            super.writeExternal(output);
    }

    /**
     *  The unique id for the message.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion BlazeDS 4
     *  @productversion LCDS 3 
     */
    override public function get messageId():String
    {
        /* If we are wrapping another message, use its messageId */
        if (_message != null)
            return _message.messageId;

        return super.messageId;
    }

    private var _message:CommandMessage;
}

}
